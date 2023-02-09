import { grpc } from "@improbable-eng/grpc-web";
import { formatError } from "@jonline/ui/src";
import { CreateAccountRequest, LoginRequest } from "@jonline/ui/src/generated/authentication";
import {
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  EntityId,
  PayloadAction
} from "@reduxjs/toolkit";
import moment from "moment";
import 'react-native-get-random-values';
import { v4 as uuidv4 } from 'uuid';
import {store, getServerClient, resetCredentialedData } from "../store";
import { AccountOrServer, JonlineAccount, JonlineCredentialClient, JonlineServer } from "../types";

export async function getCredentialClient(accountOrServer: AccountOrServer): Promise<JonlineCredentialClient> {
  let { account, server } = accountOrServer;
  if (!account) {
    return getServerClient(server!);
  } else {
    let client = await getServerClient(account.server);
    let metadata = new grpc.Metadata();
    let accessExpiresAt = moment.utc(account.accessToken.expiresAt);
    let now = moment.utc();
    let expired = accessExpiresAt.subtract(2, 'minutes').isBefore(now);
    if (expired) {
      let { accessToken, refreshToken } = await client.accessToken({ refreshToken: account.refreshToken!.token });
      account = { ...account, accessToken: accessToken! };
      store.dispatch(accountsSlice.actions.upsertAccount(account));
    }
    metadata.append('authorization', account.accessToken.token);
    return { ...client, credential: metadata };
  }
}

export interface AccountsState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  account?: JonlineAccount;
  ids: EntityId[];
  entities: Dictionary<JonlineAccount>;
}

const accountsAdapter = createEntityAdapter<JonlineAccount>({
  selectId: (account) => account.id,
});

export type CreateAccount = JonlineServer & CreateAccountRequest;
export const createAccount = createAsyncThunk<JonlineAccount, CreateAccount>(
  "accounts/create",
  async (createAccountRequest) => {
    let client = await getServerClient(createAccountRequest);
    let { refreshToken, accessToken, user } = await client.createAccount(createAccountRequest);
    let metadata = new grpc.Metadata();
    metadata.append('authorization', accessToken!.token)
    user = user || await client.getCurrentUser({}, metadata);
    return {
      id: uuidv4(),
      user: user!,
      refreshToken: refreshToken!,
      accessToken: accessToken!,
      server: { ...createAccountRequest }
    };
  }
);

export type Login = JonlineServer & LoginRequest;
export const login = createAsyncThunk<JonlineAccount, Login>(
  "accounts/login",
  async (loginRequest) => {
    let client = await getServerClient(loginRequest);
    let { refreshToken, accessToken, user } = await client.login(loginRequest);
    let metadata = new grpc.Metadata();
    metadata.append('authorization', accessToken!.token)
    user = user || await client.getCurrentUser({}, metadata);
    return {
      id: uuidv4(),
      user: user!,
      refreshToken: refreshToken!,
      accessToken: accessToken!,
      server: { ...loginRequest }
    };
  }
);

const initialState: AccountsState = {
  status: "unloaded",
  error: undefined,
  ...accountsAdapter.getInitialState(),
};

export const accountsSlice = createSlice({
  name: "accounts",
  initialState: initialState,//{ ...initialState, ...JSON.parse(localStorage.getItem("accounts")) },
  reducers: {
    upsertAccount: accountsAdapter.upsertOne,
    removeAccount: (state, action: PayloadAction<string>) => {
      if (state.account?.id === action.payload) {
        state.account = undefined;
      }
      accountsAdapter.removeOne(state, action);
    },
    resetAccounts: () => initialState,
    selectAccount: (state, action: PayloadAction<JonlineAccount | undefined>) => {
      if (state.account?.id != action.payload?.id) {
        resetCredentialedData();
      }
      state.account = action.payload;
    },
    clearAccountAlerts: (state) => {
      state.errorMessage = undefined;
      state.successMessage = undefined;
      state.error = undefined;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(createAccount.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(createAccount.fulfilled, (state, action) => {
      state.status = "loaded";
      state.account = action.payload;
      accountsAdapter.upsertOne(state, action.payload);
      state.successMessage = `Created account ${action.payload.user.username}`;
    });
    builder.addCase(createAccount.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(login.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(login.fulfilled, (state, action) => {
      state.status = "loaded";
      state.account = action.payload;
      accountsAdapter.upsertOne(state, action.payload);
      state.successMessage = `Logged in as ${action.payload.user.username}`;
    });
    builder.addCase(login.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
  },
});

export const { selectAccount, removeAccount, clearAccountAlerts, resetAccounts } = accountsSlice.actions;

export const { selectAll: selectAllAccounts, selectTotal: selectAccountTotal } = accountsAdapter.getSelectors();
export const accountsReducer = accountsSlice.reducer;
export default accountsReducer;