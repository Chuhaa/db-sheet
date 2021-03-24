import ballerina/http;
import ballerina/log;
import ballerinax/java.jdbc;
import ballerinax/googleapis_sheets as sheets;

@display { kind: "Database-URL", label: "Setup database connection" }
configurable string dbUrl = ?;

@display { kind: "Database-Table", label: "Database table" }
configurable string tableName = ?;

@display { kind: "OAuth2DirectTokenConfig", provider: "googleapis_sheets", label: "Setup GSheets connection" }
configurable http:OAuth2DirectTokenConfig & readonly sheetOauthConfig = ?;

configurable string & readonly sheetId = ?;
configurable string & readonly workSheetName = ?;

jdbc:Client jdbcClient = check new (dbUrl);

sheets:SpreadsheetConfiguration spreadsheetConfig = {
    oauthClientConfig: sheetOauthConfig
};
sheets:Client spreadsheetClient = check new (spreadsheetConfig);

public function main() returns error? {
    
    stream<record{}, error> resultStream = jdbcClient->query(string`select * from ${tableName}`);

    check resultStream.forEach(function(record {} result) {
        log:print("Details: ", result); 
        string[] values = toFieldsArray(result);
        var res = spreadsheetClient->appendRowToSheet(sheetId, workSheetName, values);
    });
}

function toFieldsArray(record {} anydataRecord) returns string[] {
    string[] fields = [];
    foreach var recField in anydataRecord {
        fields.push(recField.toString());
    }
    return fields;
}
