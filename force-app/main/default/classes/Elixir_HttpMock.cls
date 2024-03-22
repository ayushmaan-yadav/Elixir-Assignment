@isTest
global class Elixir_HttpMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a new HTTPResponse object
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status": "success", "message": "Mock response body"}');
        res.setStatusCode(200);
        return res;
    }
}