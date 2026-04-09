// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import email_group_manager.types;

import ballerina/jwt;

configurable string adminRole = ?;

# Decode JSON Web Token and return email and roles as JwtRecord.
#
# + jwt - JSON Web Token
# + return - Return payload or error
public isolated function jwtDecode(string jwt) returns types:JwtRecord|error {
    [jwt:Header, jwt:Payload] [_, payload] = check jwt:decode(jwt);
    types:JwtRecord jwtPayload = check payload.cloneWithType();
    string? email = jwtPayload.email;

    if email is () {
        return error("Invalid JWT. Could not fetch email from JWT");
    }
    return {
        email,
        groups: jwtPayload.groups
    };
}

# Check whether the user is an app admin.
#
# + jwtRecord - JSON Web Token Record
# + return - Return true if user is an admin, else false
public isolated function checkUserIsAdmin(types:JwtRecord jwtRecord) returns boolean =>
    jwtRecord.groups.indexOf(adminRole) is int;
