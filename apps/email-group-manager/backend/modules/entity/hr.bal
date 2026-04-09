// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import email_group_manager.utils;

import ballerina/graphql;

# Get employee details.
#
# + email - employee email
# + return - Employee
public isolated function getEmployeeDetails(string email) returns Employee|error {
    GetEmployeeDetailsResponse|graphql:ClientError response = hrEntityGraphqlClient->execute(
        string `
            query employeeThumbnailQuery ($email:String!) {
                employee (email: $email) {  
                    firstName
                    lastName
                    employeeThumbnail
                }
            } 
        `,
        {email}
    );

    if response is graphql:ClientError {
        return utils:handleGraphqlErrors("Error in getEmployeeDetails", response);
    }
    return response.data.employee;
}
