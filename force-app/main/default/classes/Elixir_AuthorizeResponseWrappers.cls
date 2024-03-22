/**
 * @description       : 
 * @author            : Ayushmaan Yadav 
 * @Jira Ticket       : 
 * @last modified on  : 02-11-2024
 * @last modified by  : Ayushmaan Yadav 
 * 
 **/ 
public with sharing class Elixir_AuthorizeResponseWrappers {

    public TransactionResponse transactionResponse;
	public String refId;	//123456
	public Messages messages;
    public String token;
    public String customerProfileId;
    public String customerAddressId;
	public PaymentProfile paymentProfile;
    public String subscriptionId;	//9125836
	public Profile profile;
    public List<Transactions> transactions;
	public Integer totalNumInResultSet;	//22
    
	public class Transactions {
		public String transId;	//120016726121
		public String submitTimeUTC;	//2024-02-13T09:33:28.61Z
		public String submitTimeLocal;	//2024-02-13T01:33:28.61
		public String transactionStatus;	//capturedPendingSettlement
		public String accountType;	//Visa
		public String accountNumber;	//XXXX1111
		public String invoiceNumber;
		public Decimal settleAmount;	//55
		public String marketType;	//eCommerce
		public String product;	//Card Not Present
		public Profile profile;
	}

	public class TransactionResponse {
		public String responseCode;	//1
		public String authCode;	//E22IQ5
		public String avsResultCode;	//Y
		public String cvvResultCode;	//P
		public String cavvResultCode;	//2
		public String transId;	//120016726121
		public String refTransID;	//
		public String transHash;	//
		public String testRequest;	//0
		public String accountNumber;	//XXXX1111
		public String accountType;	//Visa
		public List<Messages> messages;
		public String transHashSha2;	//
		public Profile profile;
		public String networkTransId;	//55B4HQPXYX6LM6KLFLSAN83
	}

	public class PaymentProfile {
		public String customerProfileId;	//527262
		public String customerPaymentProfileId;	//87
		public Payment payment;
		public List<String> subscriptionIds;
		public String originalNetworkTransId;	//0TN1VE648DFCJSHQ81GZH9F
		public Integer originalAuthAmount;	//0
		public BillTo billTo;
	}
	public class Payment {
		public CreditCard creditCard;
	}
	public class CreditCard {
		public String cardNumber;	//XXXX1111
		public String expirationDate;	//XXXX
		public String cardType;	//Visa
		public String issuerNumber;	//411111
	}
	public class BillTo {
		public String phoneNumber;	//000-000-0000
		public String firstName;	//John
		public String lastName;	//Doe
		public String address;	//123 Main St.
		public String city;	//Bellevue
		public String state;	//WA
		public String zip;	//98004
		public String country;	//US
	}

	public class Messages {
		public String resultCode;	//Ok
		public List<Message> message;
	}
	public class Profile {
		public String customerProfileId;	//917631459
		public String customerPaymentProfileId;	//917106785
		public String customerAddressId; //917985438
		public List<PaymentProfile> paymentProfiles;	
	}
	public class Message {
		public String code;	//I00001
		public String text;	//Successful.
	}

	public class PaymentPlanLineWrap {
		public List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList;
		/**
		* @description Set the value to the Paymet Plan Wapper.
		* @author Ayushmaan Yadav | 11th Feburary 2024
		* @param List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList
		* @returns None
		**/
		public void setPaymentPlanLine(List<ElixirSuite__Payment_Plan_Line_Item__c> paymentPlanLineList) {
			this.paymentPlanLineList = paymentPlanLineList;
		}
	}
    
}