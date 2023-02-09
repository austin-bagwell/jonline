import {
  createAsyncThunk,
  createEntityAdapter,
  createSlice,
  Dictionary,
  EntityId,
  PayloadAction
} from "@reduxjs/toolkit";
import { getServerClient, resetCredentialedData } from "../store";
import { Platform } from 'react-native';
import { JonlineServer } from "../types";

export function serverUrl(server: JonlineServer): string {
  return `http${server.secure ? "s" : ""}:${server.host}`;
}

export interface ServersState {
  status: "unloaded" | "loading" | "loaded" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  // Current server the app is pointing to.
  server?: JonlineServer;
  ids: EntityId[];
  entities: Dictionary<JonlineServer>;
}

const serversAdapter = createEntityAdapter<JonlineServer>({
  selectId: serverUrl,
});

export const upsertServer = createAsyncThunk<JonlineServer, JonlineServer>(
  "servers/create",
  async (server) => {
    // getServerClient will update/upsert the server as a side effect.
    let client = await getServerClient(server);
    // let serviceVersion: GetServiceVersionResponse = await Promise.race([client.getServiceVersion({}), timeout(5000, "service version")]);
    // let serverConfiguration = await Promise.race([client.getServerConfiguration({}), timeout(5000, "server configuration")]);
    return server;
  }
);

const initialServer: JonlineServer | undefined = Platform.OS == 'web' && globalThis.window?.location ? {
  host: window.location.hostname,
  secure: window.location.protocol == 'https:',
} : {
  host: 'jonline.io',
  secure: true,
}

const initialState: ServersState = {
  status: "unloaded",
  error: undefined,
  server: initialServer,
  ...serversAdapter.getInitialState({
    ids: initialServer ? [serverUrl(initialServer)] : [],
    entities: initialServer ? { [serverUrl(initialServer)]: initialServer } : {},
  }),
};

export const serversSlice = createSlice({
  name: "servers",
  initialState: initialState,
  reducers: {
    upsertServer: serversAdapter.upsertOne,
    removeServer: (state, action: PayloadAction<JonlineServer>) => {
      if (state.server && serverUrl(state.server) == serverUrl(action.payload)) {
        state.server = undefined;
      }
      serversAdapter.removeOne(state, serverUrl(action.payload));
    },
    resetServers: () => initialState,
    clearServerAlerts: (state) => {
      state.errorMessage = undefined;
      state.successMessage = undefined;
      state.error = undefined;
    },
    selectServer: (state, action: PayloadAction<JonlineServer | undefined>) => {
      let currentUrl = state.server ? serverUrl(state.server) : undefined;
      if (currentUrl != serverUrl(action.payload!)) {
        resetCredentialedData();
      }
      state.server = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(upsertServer.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(upsertServer.fulfilled, (state, action) => {
      state.status = "loaded";
      let server = action.payload
      serversAdapter.upsertOne(state, action.payload);
      if (!state.server || serverUrl(server) == serverUrl(state.server!)) {
        state.server = server;
      }
      console.log(`Server ${action.payload.host} running Jonline v${action.payload.serviceVersion?.version} added.`);
      state.successMessage = `Server ${action.payload.host} running Jonline v${action.payload.serviceVersion?.version} added.`;
    });
    builder.addCase(upsertServer.rejected, (state, action) => {
      state.status = "errored";
      console.error(`Error connecting to ${action.meta.arg.host}.`, action.error);
      state.errorMessage = `Error connecting to ${action.meta.arg.host}.`;
      state.error = action.error as Error;
    });
  },
});

export const { selectServer, removeServer, clearServerAlerts, resetServers } = serversSlice.actions;

export const { selectAll: selectAllServers, selectById: selectServerById, selectTotal: selectServerTotal } = serversAdapter.getSelectors();

export const serversReducer = serversSlice.reducer;
export default serversReducer;