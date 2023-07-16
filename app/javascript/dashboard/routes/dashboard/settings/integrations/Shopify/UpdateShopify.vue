<template>
  <div class="column content-box">
    <woot-modal-header
        :header-title="$t('INTEGRATION_SETTINGS.SHOPIFY.EDIT.TITLE')"
    />
    <form class="row" @submit.prevent="editShopify">
      <div class="medium-12 columns">
        <label :class="{ error: $v.accountName.$error }">
          {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.ACCOUNT_NAME.LABEL') }}
          <input
              v-model.trim="accountName"
              type="text"
              name="accountName"
              :placeholder="
                $t(
                  'INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.ACCOUNT_NAME.PLACEHOLDER'
                )
              "
              v-on:keydown="resetAllowance"
              @input="$v.accountName.$touch"
          />
          <span v-if="$v.accountName.$error" class="message">
              {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.ACCOUNT_NAME.ERROR') }}
            </span>
        </label>

        <label :class="{ error: $v.accessToken.$error }">
          {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.ACCESS_TOKEN.LABEL') }}
          <input
              v-model.trim="accessToken"
              type="text"
              name="accessToken"
              :placeholder="
                $t(
                  'INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.ACCESS_TOKEN.PLACEHOLDER'
                )
              "
              v-on:keydown="resetAllowance"
              @input="$v.accessToken.$touch"
          />
          <span v-if="$v.accessToken.$error" class="message">
              {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.ACCESS_TOKEN.ERROR') }}
            </span>
        </label>

        <label :class="{ error: $v.apiVersion.$error }">
          {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_VERSION.LABEL')}}
          <input
            v-model.trim="apiVersion"
            type="text"
            name="apiVersion"
            :placeholder="
              $t(
                'INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM_API_VERSION.PLACEHOLDER'
              )
            "
            v-on:keydown="resetAllowance"
            @input="$v.apiVersion.$touch"
          /> 
        </label>
      </div>

      <div class="modal-footer">
        <div class="medium-12 columns">
          <woot-button class="button"  color-scheme="success" @click.prevent="onAuthorize">
            {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.AUTHORIZE') }}
          </woot-button>
          <woot-button
              :is-disabled="
              $v.accessToken.$invalid || $v.accountName.$invalid || uiFlags.updatingItem || !allowCreate
            "
              :is-loading="uiFlags.updatingItem"
          >
            {{ $t('INTEGRATION_SETTINGS.SHOPIFY.EDIT.FORM.SUBMIT') }}
          </woot-button>
          <woot-button class="button clear" @click.prevent="onClose">
            {{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.CANCEL') }}
          </woot-button>
        </div>
      </div>
    </form>
  </div>
</template>

<script>
import {required, url, minLength, maxLength} from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import {mapGetters} from 'vuex';
import moment from "moment";
import shopifyApi from "../../../../../api/shopify.js"
export default {
  mixins: [alertMixin],
  props: {
    accountName: {
      type: String,
      required: true,
    },
    accessToken: {
      type: String,
      required: true,
    },
    apiVersion: {
      type: String,
      required: true
    },
    onClose: {
      type: Function,
      required: true,
    },
    id: {
      type: Number,
      required: true
    },
    updatedAt: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      shopfiyId: this.id,
      allowCreate: !true
    };
  },
  validations: {
    accountName: {
      required,
      minLength: minLength(3)
    },
    accessToken: {
      required,
      minLength: minLength(32),
      maxLength: maxLength(40)
    },
    apiVersion: {
      required,
      minLength: minLength(7),
      maxLength: maxLength(7)
    }
  },
  computed: {
    ...mapGetters({uiFlags: 'webhooks/getUIFlags'}),
  },
  methods: {
    getAuthorizePopup(){
      shopifyApi.checkAccessToken(this.id, this.accountName, this.accessToken, this.apiVersion).then(data => {
        if(Object.keys(data.data).includes("success")){
          this.alertMessage = this.$t('INTEGRATION_SETTINGS.SHOPIFY.EDIT.CHECK.SUCCESS_MESSAGE');
          this.allowCreate = true;
        } else {
          this.alertMessage = this.$t('INTEGRATION_SETTINGS.SHOPIFY.EDIT.CHECK.ERROR_MESSAGE');
        }
        this.showAlert(this.alertMessage);
      });
    },
    resetAllowance(){
      this.allowCreate = null;
    },
    closeAuthorizePopup(){
      this.showAuthorizePopup = false;
    },
    resetForm() {
      this.accountName = '';
      this.accessToken = '';
      this.$v.accountName.$reset();
      this.$v.accessToken.$reset();
    },
    onAuthorize(){
      this.getAuthorizePopup();
    },
    async editShopify() {
      try {
        await this.$store.dispatch('shopify/update', {
          id: this.shopfiyId,
          account_name: this.accountName,
          access_token: this.accessToken,
          api_version: this.apiVersion
        });
        this.alertMessage = this.$t(
            'INTEGRATION_SETTINGS.SHOPIFY.EDIT.API.SUCCESS_MESSAGE'
        );
        await this.$store.dispatch('shopify/get');
      } catch (error) {
        this.alertMessage = this.$t('INTEGRATION_SETTINGS.SHOPIFY.EDIT.API.ERROR_MESSAGE');
      } finally {
        this.resetForm();
        this.onClose();
        this.showAlert(this.alertMessage);
      }
    },
    moment(){
      return new moment();
    }
  },
};
</script>
