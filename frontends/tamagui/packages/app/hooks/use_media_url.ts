import { AccountOrServer, JonlineServer, serverUrl, useCredentialDispatch, frontendServerUrl } from 'app/store';

export function useMediaUrl(mediaId?: string, override?: AccountOrServer): string | undefined {
  const { accountOrServer: { account: currentAccount, server: currentServer } } = useCredentialDispatch();
  const {account: overrideAccount, server: overrideServer} = override ?? {};

  const account = overrideAccount ?? currentAccount;
  const server = overrideServer ?? currentServer;
  if (!mediaId || mediaId == '') return undefined;

  if (account && !override) {
    return `${frontendServerUrl(server!)}/media/${mediaId}?authorizaton=${account.accessToken.token}`;
  }
  return `${frontendServerUrl(server!)}/media/${mediaId}`;
}
