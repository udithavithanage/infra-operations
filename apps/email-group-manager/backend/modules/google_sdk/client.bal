// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import ballerina/http;
import ballerina/jwt;

configurable OAuthClientConfig config = ?;
configurable string defaultUser = ?;
configurable string publicGroupUser = ?;
configurable string privateGroupUser = ?;

function generateAssertion(OAuthClientConfig config) returns string|error {
    return jwt:issue(
            {
                issuer: config.issuer,
                audience: config.audience,
                expTime: 3600,
                customClaims: {
                    scope: config.scopes,
                    sub: config.subject
                },
                signatureConfig: {
                    config: {
                        keyStore: {
                            path: config.certPath,
                            password: config.password
                        },
                        keyAlias: config.keyAlias,
                        keyPassword: config.keyPassword
                    }
                }
            }
    );
}

final http:Client adminClient = check new ("https://admin.googleapis.com", {
    auth: {
        tokenUrl: "https://oauth2.googleapis.com/token",
        assertion: check generateAssertion(config)
    }
});
