@RestResource(urlMapping='/senna/*')
global with sharing class SennaAPI {

    @HttpPost
    global static SennaResponse handleRequest() {
        SennaResponse response = new SennaResponse();
        try {
            RestRequest request = RestContext.request;
            String requestBody = request.requestBody.toString();

            SennaRequest sennaRequest = (SennaRequest) JSON.deserialize(requestBody, SennaRequest.class);

            String action = sennaRequest.action != null ? sennaRequest.action.toLowerCase() : '';

            if (action == 'select') {
                response = handleSelect(sennaRequest.data);
            } else {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(sennaRequest.data);
                String objectType = (String) data.get('objectType');
                Map<String, Object> fields = (Map<String, Object>) data.get('fields');
                Id recordId = (Id) data.get('recordId');
                
                if (action == 'insert') {
                    response = handleInsert(objectType, fields);
                } else if (action == 'update') {
                    if (recordId == null) {
                        throw new IllegalArgumentException('Record ID is required for update.');
                    }
                    response = handleUpdate(objectType, fields, recordId);
                } else if (action == 'delete') {
                    if (recordId == null) {
                        throw new IllegalArgumentException('Record ID is required for delete.');
                    }
                    response = handleDelete(objectType, recordId);
                } else {
                    response.status = 'Error';
                    response.message = 'Invalid action. Only "select", "insert", "update", and "delete" are supported.';
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' Stack trace: ' + e.getStackTraceString());
            response.status = 'Error';
            response.message = 'An error occurred: ' + e.getMessage();
        }
        return response;
    }

    private static SennaResponse handleSelect(String query) {
        SennaResponse response = new SennaResponse();
        try {
            List<SObject> records = Database.query(query);
            response.records = records;
            response.status = 'Success';
            response.message = 'Query executed successfully.';
        } catch (Exception e) {
            System.debug('Error in handleSelect: ' + e.getMessage());
            response.status = 'Error';
            response.message = 'Error executing query: ' + e.getMessage();
        }
        return response;
    }

    private static SennaResponse handleInsert(String objectType, Map<String, Object> fields) {
        SennaResponse response = new SennaResponse();
        try {
            SObject record = createSObject(objectType, fields);
            insert record;
            response.records = new List<SObject> { record };
            response.status = 'Success';
            response.message = 'Record inserted successfully.';
        } catch (Exception e) {
            System.debug('Error inserting record: ' + e.getMessage() + ' Stack trace: ' + e.getStackTraceString());
            response.status = 'Error';
            response.message = 'Error inserting record: ' + e.getMessage();
        }
        return response;
    }

    private static SennaResponse handleUpdate(String objectType, Map<String, Object> fields, Id recordId) {
        SennaResponse response = new SennaResponse();
        try {
            SObject record = createSObject(objectType, fields);
            record.Id = recordId;
            update record;
            response.records = new List<SObject> { record };
            response.status = 'Success';
            response.message = 'Record updated successfully.';
        } catch (Exception e) {
            System.debug('Error updating record: ' + e.getMessage() + ' Stack trace: ' + e.getStackTraceString());
            response.status = 'Error';
            response.message = 'Error updating record: ' + e.getMessage();
        }
        return response;
    }

    private static SennaResponse handleDelete(String objectType, Id recordId) {
        SennaResponse response = new SennaResponse();
        try {
            SObject record = createSObject(objectType, new Map<String, Object>());
            record.Id = recordId;
            delete record;
            response.records = new List<SObject> { record };
            response.status = 'Success';
            response.message = 'Record deleted successfully.';
        } catch (Exception e) {
            System.debug('Error deleting record: ' + e.getMessage() + ' Stack trace: ' + e.getStackTraceString());
            response.status = 'Error';
            response.message = 'Error deleting record: ' + e.getMessage();
        }
        return response;
    }

	private static SObject createSObject(String objectType, Map<String, Object> fields) {
    	SObject record = (SObject) Type.forName('Schema.' + objectType).newInstance();
    	Map<String, Schema.SObjectField> fieldMap = record.getSObjectType().getDescribe().fields.getMap();

    	for (String field : fields.keySet()) {
        	Object value = fields.get(field);
        // Verifica se o campo é uma data e converte a string para Date
        	if (fieldMap.containsKey(field) && fieldMap.get(field).getDescribe().getType() == Schema.DisplayType.Date && value instanceOf String) {
            	value = Date.valueOf((String) value);
        	}	
        	record.put(field, value);
    	}
    	return record;
	}

    global class SennaResponse {
        public String message;
        public String status;
        public List<SObject> records;
    }

    global class SennaRequest {
        public String action;
        public String data;
    }
}