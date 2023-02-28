/* global axios */
import ApiClient from './ApiClient';

class ShopifyAPI extends ApiClient {
  constructor() {
    super('integrations/shopify', { accountScoped: true, apiVersion: 'v1' });
  }
  checkAccessToken(id, accountName, accessToken, apiVersion){
    return axios.post(`${this.url}/${id}/check_access_token`, {
      api_version: apiVersion,
      access_token: accessToken,
      account_name: accountName
    });
  }
}
export default new ShopifyAPI();