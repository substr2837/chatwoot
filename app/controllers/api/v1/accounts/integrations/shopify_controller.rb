class Api::V1::Accounts::Integrations::ShopifyController < Api::V1::Accounts::BaseController
  before_action :fetch_shopify, only: [:update, :destroy]
  before_action :check_authorization?

  def index
    @shopify_list = Array.new
    Current.account.hooks.where(app_id: "SHOPIFY").each do |hook|
      @shopify_list.append(map_hook_to_integration(hook))
    end

    render json: @shopify_list
  end

  def create
    @shopify = map_integration_to_map(Current.account.hooks.new)
    @shopify.app_id = "SHOPIFY"
    @shopify.save!
    render json: @shopify
  end

  def update
    shopify_modify = map_integration_to_map(Current.account.hooks.find(shopify_params[:id]))
    shopify_modify.app_id = "SHOPIFY"
    @shopify.update!(shopify_modify.as_json)
  end

  def destroy
    @shopify.destroy!
    head :ok
  end

  def make_refund
    shopify_customer = Integrations::ShopifyCustomer.find_by(contact_id: params[:contact_id])
    shopify_account = Integrations::Shopify.find_by(id: shopify_customer.shopify_account_id)
    error = false
    if !shopify_account.nil?
      begin
        refund = Hash.new
        refund["refund"] = Hash.new
        refund["refund"]["shipping"] = Hash.new
        refund["refund"]["shipping"]["full_refund"] = params[:shipping_refund_status]
        refund["refund"]["shipping"]["amount"] = params[:shipping_refund_amount]
        item = Hash.new
        item["line_item_id"] = params[:item_id]
        item["quantity"] = params[:refund_quantity]
        item["restock_type"] = params[:restock_type]
        refund["refund"]["refund_line_items"] = Array.new(1){
          item
        }
        response = RestClient.post 'https://'+shopify_account.account_name+'/admin/api/2022-04/orders/'+params[:order_id].to_s+'/refunds/calculate.json',
        refund.to_json,
        {
          content_type: :json,
          accept: :json,
          "X-Shopify-Access-Token": shopify_account.access_token
        }
      rescue RestClient::ExceptionWithResponse => err
        response = err.response.body
        error = true
      end
      if error
        return render json: response, :status => :bad_request
      end
      # Calculate refund
      refund = Hash.new
      refund["refund"] = Hash.new
      refund["refund"]["shipping"] = Hash.new
      refund["refund"]["shipping"]["full_refund"] = params[:shipping_refund_status]
      refund["refund"]["shipping"]["amount"] = params[:shipping_refund_amount]
      refund["refund"]["transactions"] = JSON.parse(response, object_class: Hash)["refund"]["transactions"]

      begin
        response = RestClient.post 'https://'+shopify_account.account_name+'/admin/api/2022-04/orders/'+params[:order_id].to_s+'/refunds.json',
        refund.to_json,
        {
          content_type: :json,
          accept: :json,
          "X-Shopify-Access-Token": shopify_account.access_token
        }
      rescue RestClient::ExceptionWithResponse => err
        response = err.response.body
      end

      render json: response
    else
      render json: {"message"=>"Invalid shopify account"}
    end
  end

  def check_access_token
    begin
      response = RestClient.get "https://#{params[:account_name]}/admin/api/#{params[:api_version]}/shop.json",
      {
        content_type: :json,
        "X-Shopify-Access-Token": "#{params[:access_token]}"
      }
    rescue RestClient::ExceptionWithResponse => err
      response = err.response.body
    end

    @response_obj = JSON.parse(response, object_class: OpenStruct)

    unless !@response_obj[:errors].nil?
      render json: {"success"=>"true"}
    else
      render json: {"error"=>"true"}
    end
  end

  private

  def shopify_params
    params.require(:shopify).permit(:id, :account_name, :access_token, :api_version)
  end

  def fetch_shopify
    @shopify = Current.account.hooks.find(params[:id])
  end

  def check_authorization?
    authorize(:shopify)
  end

  def map_hook_to_integration(hook)
    setting_json = JSON.parse(hook.settings)
    @integration = {
      "account_name" => setting_json["accountname"],
      "api_version" => setting_json["apiversion"],
      "access_token" => hook.access_token,
      "id" => hook.id
    }
  end

  def map_integration_to_map(shopify)
    shopify.id = shopify_params[:id]
    setting_json = {
      "accountname" => shopify_params[:account_name],
      "apiversion" => shopify_params[:api_version]
    }
    shopify.settings = JSON[setting_json]
    shopify.app_id = @shopify_id
    shopify.access_token = shopify_params[:access_token]
    shopify
  end

end
