class ShopifyApiController < ApplicationController
    before_action :fetch_all_integration_accounts
    def get_from_shopify
        @shopify_intg.each do |intg|
            path = construct_url(intg, request.path)
            do_request(path, "GET", nil, intg[:access_token])
        end
    end

    def post_from_shopify
        @shopify_intg.each do |intg|
            path = construct_url(intg, request.path)
            do_request(path, "POST", request.body.read, intg[:access_token])
        end
    end

    def put_from_shopify
        @shopify_intg.each do |intg|
            path = construct_url(intg, request.path)
            do_request(path, "PUT", request.body.read, intg[:access_token])
        end
    end

    def patch_from_shopify
        @shopify_intg.each do |intg|
            path = construct_url(intg, request.path)
            do_request(path, "PUT", request.body.read, intg[:access_token])
        end
    end

    def fetch_all_integration_accounts
        @shopify_intg = Current.account.hooks.where app_id: "SHOPIFY"
    end

    def construct_url(intg, path)
        # remove /shopifyapi
        path = path.sub("/shopifyapi", "/")
        # combine the path with shopify base url
        setting_json = JSON.parse(intg[:settings])
        path = "https://#{setting_json["accountname"]} /#{setting_json["apiversion"]}#{path}"
        path
    end

    def do_request(path, method, body, access_token)
        begin
            if method.cacecmp?("GET")
                response = RestClient.get path
                {
                    content_type: :json,
                    "X-Shopify-Access-Token": "#{access_token}"
                }
            elsif method.casecmp?("POST")
                response = RestClient.post path
                body.to_json,
                {
                    content_type: :json
                    "X-Shopify-Access-Token": "#{access_token}"
                }
            elsif method.casecmp?("PATCH")
                response = RestClient.patch path
                body.to_json,
                {
                    content_type: :json
                    "X-Shopify-Access-Token": "#{access_token}"
                }
            elsif method.casecmp?("PUT")
                response = RestClient.put path
                body.to_json,
                {
                    content_type: :json
                    "X-Shopify-Access-Token": "#{access_token}"
                }
            end
            response
        rescue RestClient::ExceptionWithResponse => err
            err.response.body
        end
    end
end
