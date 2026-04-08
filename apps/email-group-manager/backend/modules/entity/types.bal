// Copyright (c) 2023, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import ballerina/graphql;

# Domain entity client auth configurations.
type ClientAuthConfig record {|
    # Token URL as a string
    string tokenUrl;
    # Client Id as a string
    string clientId;
    # Client Secret as a string
    string clientSecret;
|};

# Employee details.
public type Employee record {|
    # Employee's thumbnail image URL
    string? employeeThumbnail;
    # First name as a string
    string firstName;
    # Last name as a string
    string lastName;
|};

# Get employee details graphql response.
type GetEmployeeDetailsResponse record {|
    *graphql:GenericResponseWithErrors;
    # Employee details record
    record {
        Employee employee;
    } data;
|};
