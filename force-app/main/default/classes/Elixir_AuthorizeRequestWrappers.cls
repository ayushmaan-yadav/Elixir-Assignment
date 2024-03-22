/**
 * @description       : 
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/ 
public with sharing class Elixir_AuthorizeRequestWrappers {

	private static final String AUTH_CAPTURE_TRANSACTION = 'authCaptureTransaction';
	private static  final String RESUBMISSION = 'resubmission';

	public CreateCustomerProfileRequest createCustomerProfileRequest;
	public GetHostedPaymentPageRequest getHostedPaymentPageRequest;
	public GetTransactionListForCustomerRequest getTransactionListForCustomerRequest;
	public ARBCreateSubscriptionRequest ARBCreateSubscriptionRequest;
	public ARBCancelSubscriptionRequest ARBCancelSubscriptionRequest;
	public CreateTransactionRequest createTransactionRequest;
	public CreateCustomerShippingAddressRequest createCustomerShippingAddressRequest;
	public GetCustomerPaymentProfileRequest getCustomerPaymentProfileRequest;
	
	
	
	public virtual class TemplateRequest {
		private MerchantAuthentication merchantAuthentication;
		private String refId;

		public TemplateRequest(Elixir_AuthorizeCallout authCallout) {
			merchantAuthentication = new MerchantAuthentication();
			merchantAuthentication.name = authCallout.getAPIKey();
			merchantAuthentication.transactionKey = authCallout.getTransactionKey();
		}

		public void setRefId(String refId) {
			this.refId = refId;
		}
	}

	public class CreateCustomerProfileRequest extends TemplateRequest {
		private Profile profile;
		
		public CreateCustomerProfileRequest(Elixir_AuthorizeCallout authCallout,Account acc) {
			super(authCallout);
			profile = new Profile(false);
			setAccountRelatedFields(acc);
		}

		private void setAccountRelatedFields(Account acc){ 
			profile.description = acc.ElixirSuite__First_Name__c;
        	profile.email = acc.ElixirSuite__Email_Id__c;
		}


	}
	
	public class GetHostedPaymentPageRequest extends TemplateRequest {
		private TransactionRequest transactionRequest;
		public HostedPaymentSettings hostedPaymentSettings;

		public GetHostedPaymentPageRequest(Elixir_AuthorizeCallout authCallout,Account acc) {
			super(authCallout);
			hostedPaymentSettings  = new HostedPaymentSettings();
			transactionRequest = new TransactionRequest(false);
			setAccountRelatedFields(acc);
		}

		public void setInvoiceNumber(String  invoiceNum) {
			transactionRequest.order.invoiceNumber = invoiceNum;
		}

		public void setTransactionAmount(Decimal amountToCharge){
			transactionRequest.amount = String.ValueOf(amountToCharge);
		}

		private void setAccountRelatedFields(Account acc){ 
			transactionRequest.profile.customerPaymentProfileId = acc.Elixir_Authorize_Customer_Profile_Id__c;
			transactionRequest.customer.email = acc.ElixirSuite__Email_Id__c;
			Address address = new Address();
			address.firstName = acc.ElixirSuite__First_Name__c;
			address.lastName = acc.ElixirSuite__Last_Name__c;	
			address.address = acc.BillingStreet;
			address.city = acc.BillingCity;
			address.state = acc.BillingState;
			address.zip = acc.BillingPostalCode;
			address.country = acc.BillingCountry;
			transactionRequest.billTo = address;
			transactionRequest.transactionType = AUTH_CAPTURE_TRANSACTION;
		}

	}

	public class GetTransactionListForCustomerRequest extends TemplateRequest {
		public String customerProfileId;	//40025205
		public Sorting sorting;
		public Paging paging;

		public GetTransactionListForCustomerRequest(Elixir_AuthorizeCallout authCallout, String profileID) {
			super(authCallout);
			this.sorting = new Sorting();
			this.paging = new Paging();
			this.customerProfileId = profileID;
			this.setSortingAndPaging();
		}

		private void setSortingAndPaging() {
			sorting.orderBy = 'submitTimeUTC';
			sorting.orderDescending = 'true';
			paging.limitNew = '5';
			paging.offset = '1';
		}
	}

	public class ARBCreateSubscriptionRequest extends TemplateRequest {
		private Subscription subscription;

		public ARBCreateSubscriptionRequest(Elixir_AuthorizeCallout authCallout,Account acc) {
			super(authCallout);
			subscription = new Subscription();
			setAccountRelatedFields(acc);
		}

		public void setSubscriptionName(String name){
			subscription.name = name;
		}

		public void setPaymentPlanDetails(ElixirSuite__Payment_Plan__c paymentPan) {
			subscription.paymentSchedule.interval.length = '';
			subscription.paymentSchedule.interval.unit = '';
			subscription.paymentSchedule.startDate = '2030-12-01'; //'YYYY-MM-DD'
			subscription.paymentSchedule.totalOccurrences = '12';
			subscription.paymentSchedule.trialOccurrences = '1';
			subscription.amount = '100.0';
			subscription.trialAmount = '0.0';
		}

		private void setAccountRelatedFields(Account acc){ 
			subscription.profile.customerProfileId = acc.Elixir_Authorize_Customer_Profile_Id__c;
			subscription.profile.customerAddressId = acc.Elixir_Authorize_Customer_Address_Id__c;
		}
	}

	public class ARBCancelSubscriptionRequest extends TemplateRequest {
		private String subscriptionId;	//100748

		public ARBCancelSubscriptionRequest(Elixir_AuthorizeCallout authCallout,String subscriptionId) {
			super(authCallout);
			this.subscriptionId = subscriptionId;
		}
	}

	public class CreateTransactionRequest extends TemplateRequest {
		private TransactionRequest transactionRequest;

		public CreateTransactionRequest(Elixir_AuthorizeCallout authCallout,String customerProfileId) {
			super(authCallout);
			transactionRequest = new TransactionRequest(true);
			transactionRequest.profile.customerProfileId = customerProfileId;
			transactionRequest.transactionType = AUTH_CAPTURE_TRANSACTION;
		}

		public void setTransactionAmount(Decimal amountToCharge){
			transactionRequest.amount = String.ValueOf(amountToCharge);
		}

		public void setPreviousPaymentInfo(ElixirSuite__Payment_Information__c paymentInfo){
			transactionRequest.subsequentAuthInformation.originalAuthAmount = paymentInfo.Elixir_Original_Authorize_Amount__c ;
			transactionRequest.subsequentAuthInformation.originalNetworkTransId = paymentInfo.Elixir_Original_Network_Transaction_Id__c;
			transactionRequest.subsequentAuthInformation.reason = RESUBMISSION;
			transactionRequest.profile.paymentProfile.paymentProfileId = paymentInfo.ElixirSuite__Source_Id__c;
		}

	}

	public class CreateCustomerShippingAddressRequest extends TemplateRequest {
		public String customerProfileId;	//917631459
		public Address address;
		public boolean defaultShippingAddress;

		public CreateCustomerShippingAddressRequest(Elixir_AuthorizeCallout authCallout,Account acc) {
			super(authCallout);
			setAccountRelatedFields(acc);
		}

		private void setAccountRelatedFields(Account acc){ 
			customerProfileId = acc.Elixir_Authorize_Customer_Profile_Id__c;
			address = new Address();
			address.firstName = acc.ElixirSuite__First_Name__c;
			address.lastName = acc.ElixirSuite__Last_Name__c;	
			address.address = acc.BillingStreet;
			address.city = acc.BillingCity;
			address.state = acc.BillingState;
			address.zip = acc.BillingPostalCode;
			address.country = acc.BillingCountry;
		}

	}

	public  class GetCustomerPaymentProfileRequest extends TemplateRequest {
		public String customerProfileId;	//10000
		public String customerPaymentProfileId;	//20000;/
		public boolean unmaskExpirationDate; // True
		public String includeIssuerInfo;	//true

		public GetCustomerPaymentProfileRequest(Elixir_AuthorizeCallout authCallout,String customerProfileId,String customerPaymentProfileId) {
			super(authCallout);
		}
	}

	public class MerchantAuthentication {
		public String name;	//7Z32qYx9
		public String transactionKey;	//5xu4Sf23UQd6F4j2
	}

	public class Profile {
		public String description;	//Name
		public String email;	//ayushmaan.yadav+Test@mirketa.com
		public String customerProfileId;	//917631459
		public String customerPaymentProfileId;	//917101787
		public String customerAddressId;	//40338125
		public PaymentProfile paymentProfile;

		Profile(boolean intializePaymentProfile) {
			if (intializePaymentProfile) {
				paymentProfile = new PaymentProfile();
			}
		}
	}

	public class Address {
		public String firstName;	//John
		public String lastName;	//Doe
		public String company;	//
		public String address;	//123 Main St.
		public String city;	//Bellevue
		public String state;	//WA
		public String zip;	//98004
		public String country;	//US
		public String phoneNumber;	//000-000-0000
		public String faxNumber;	//
	}

	public class HostedPaymentSettings {
		public List<Setting> setting;

		HostedPaymentSettings() {
			setting = new List<Setting>();
		}
	}

	public class Setting {
		public String settingName;	//hostedProfileReturnUrl
		public String settingValue;	//https://google.com/
	}

	public class Sorting {
		public String orderBy;	//id
		public String orderDescending;	//false
	}
	public class Paging {
		public String limitNew;	//10
		public String offset;	//1
	}
	
	public class Subscription {
		public String name;	//Sample subscription
		public PaymentSchedule paymentSchedule;
		public String amount;	//10.29
		public String trialAmount;	//0.00
		public Profile profile;

		Subscription() {
			profile = new Profile(true);
			paymentSchedule = new PaymentSchedule();
		}
	}

	public class PaymentSchedule {
		public Interval interval;
		public String startDate;	//2020-08-30
		public String totalOccurrences;	//12
		public String trialOccurrences;	//1

		PaymentSchedule() {
			interval = new Interval();
		}
	}

	public class Interval {
		public String length;	//1
		public String unit;	//months
	}

	public class TransactionRequest {
		public String transactionType;	//authCaptureTransaction
		public String amount;	//55
		public Profile profile;
		public Order order;
		public Customer customer;
		public Address billTo;
		public SubsequentAuthInformation subsequentAuthInformation;

		TransactionRequest(boolean includeSubsequentAuthInformation) {
			order = new Order();
			customer = new Customer();
			billTo = new Address();
			if (includeSubsequentAuthInformation) {
				subsequentAuthInformation = new SubsequentAuthInformation();
			}
			profile = new Profile(false);
		}
	}

	public class PaymentProfile {
		public String paymentProfileId;	//917101787
	}

	public class SubsequentAuthInformation {
		public String originalNetworkTransId;	//120015247420
		public String originalAuthAmount;	//20.00
		public String reason;	//resubmission
	}

	public class Order {
		public String invoiceNumber;	//IN0000002
		public String description;	//Meds
	}

	public class Customer {
		public String email;	//ayushmaan.yadav@mirketa.com
	}
	


    
}