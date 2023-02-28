<template>
	<div class="column content-box">
		<woot-modal-header
				:header-title="$t('INTEGRATION_SETTINGS.SHOPIFY.ADD.TITLE')"
				:header-content="
		useInstallationName(
		$t('INTEGRATION_SETTINGS.SHOPIFY.ADD.DESC'),
		globalConfig.installationName
		)
	"
		/>
		<form class="row" @submit.prevent="addShopifyAccount">
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
						:placeholder= "
							$t(
								'INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.API_VERSION.PLACEHOLDER'
							)
						"
						@input="$v.apiVersion.$touch"
					/>
				</label>
			</div>

			<div class="modal-footer">
				<div class="medium-12 columns">
					<woot-button class="button success" @click.prevent="onAuthorize">
						{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.AUTHORIZE') }}
					</woot-button>
					<woot-button
							:disabled="$v.accountName.$invalid || $v.accessToken.$invalid || $v.apiVersion.$invalid || addShopify.showLoading"
							:is-loading="addShopify.showLoading"
					>
						{{ $t('INTEGRATION_SETTINGS.SHOPIFY.ADD.FORM.SUBMIT') }}
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
import Modal from '../../../../../components/Modal';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import {mapGetters} from 'vuex';

export default {
	components: {
		Modal,
	},
	mixins: [alertMixin, globalConfigMixin],
	props: {
		onClose: {
			type: Function,
			required: true,
		},
	},
	data() {
		return {
			accountName: '',
			accessToken: '',
			apiVersion: '',
			addShopify: {
				showAlert: false,
				showLoading: false,
			},
			show: true,
		};
	},
	computed: {
		...mapGetters({globalConfig: 'globalConfig/get'}),
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
	methods: {
		resetForm() {
			this.accountName = '';
			this.accessToken = '';
			this.apiSecret = '';
			this.redirectUrl = '';
			this.$v.accountName.$reset();
			this.$v.accessToken.$reset();
		},
		onAuthorize(){
			this.showAlert("Authorized successfully");
		},
		async addShopifyAccount() {
			this.addShopify.showLoading = true;
			debugger;

			try {
				await this.$store.dispatch('shopify/create', {
					shopify: {
						account_name: this.accountName,
						access_token: this.accessToken,
						api_version: this.apiVersion
					},
				});
				this.addShopify.showLoading = false;

				this.addShopify.message = this.$t(
						'INTEGRATION_SETTINGS.SHOPIFY.ADD.API.SUCCESS_MESSAGE'
				);
			} catch (error) {
				this.addShopify.showLoading = false;
				this.addShopify.message = this.$t('INTEGRATION_SETTINGS.SHOPIFY.EDIT.API.ERROR_MESSAGE');
			} finally {
				this.resetForm();
				this.onClose();
				this.addShopify.showLoading = false;
				this.showAlert(this.addShopify.message);
			}
		},
	},
};
</script>
