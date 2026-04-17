// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import email_group_manager.authorization;
import email_group_manager.google_sdk;
import email_group_manager.people;
import email_group_manager.types;
import email_group_manager.utils;

import ballerina/cache;
import ballerina/http;
import ballerina/log;

final cache:Cache cache = new ({
    capacity: 2000,
    defaultMaxAge: 1800.0,
    cleanupInterval: 900.0
});

service http:InterceptableService / on new http:Listener(9090) {

    # Request interceptor.
    #
    # + return - authorization:JwtInterceptor, BadRequestInterceptor
    public function createInterceptors() returns http:Interceptor[] =>
        [new authorization:JwtInterceptor(), new BadRequestInterceptor()];

    # Fetch logged-in user's details.
    #
    # + return - User information or InternalServerError
    resource function get user\-info(http:RequestContext ctx) returns UserInfo|http:InternalServerError {
        // User information header.
        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            log:printError(USER_INFO_HEADER_NOT_FOUND_ERROR, userInfo);
            return <http:InternalServerError>{
                body: {
                    message: USER_INFO_HEADER_NOT_FOUND_ERROR
                }
            };
        }

        // Check if the employees are already cached.
        if cache.hasKey(userInfo.email) {
            UserInfo|error cachedUserInfo = cache.get(userInfo.email).ensureType();
            if cachedUserInfo is UserInfo {
                return cachedUserInfo;
            }
        }

        people:Employee|error? employee = people:fetchEmployee(userInfo.email);
        if employee is error {
            string customError = string `Error occurred while fetching user information: ${userInfo.email}`;
            log:printError(customError, employee);
            return <http:InternalServerError>{
                body: customError
            };
        }
        if employee is () {
            log:printError(string `No employee information found for the user: ${userInfo.email}`);
            return <http:InternalServerError>{
                body: {
                    message: "No information found for the user!"
                }
            };
        }

        // Fetch the user's privileges based on the roles.
        int[] privileges = [];
        if authorization:checkPermissions([...authorization:authorizedRoles.EMPLOYEE_ROLE], userInfo.groups) {
            privileges.push(authorization:EMPLOYEE_PRIVILEGE);
        }
        if authorization:checkPermissions([authorization:authorizedRoles.ADMIN_ROLE], userInfo.groups) {
            privileges.push(authorization:SECURITY_ADMIN_PRIVILEGE);
        }

        UserInfo userInfoResponse = {...employee, privileges};

        error? cacheError = cache.put(userInfo.email, userInfoResponse);
        if cacheError is error {
            log:printError("An error occurred while writing user info to the cache", cacheError);
        }
        return userInfoResponse;
    }

    # Get default google groups. All employees are subscribed to these google groups by default.
    #
    # + return - default google groups as a string array
    resource function get default\-google\-groups(http:RequestContext ctx)
        returns string[]|http:Unauthorized|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            log:printError(USER_INFO_HEADER_NOT_FOUND_ERROR, userInfo);
            return <http:InternalServerError>{
                body: {
                    message: USER_INFO_HEADER_NOT_FOUND_ERROR
                }
            };
        }

        string[]|error defaultGoogleGroups = google_sdk:getDefaultGoogleGroups();
        if defaultGoogleGroups is error {
            log:printError(string `Error in getting default google groups`, 'error = defaultGoogleGroups,
                    stackTrace = defaultGoogleGroups.stackTrace(), userEmail = userInfo.email);
            return http:INTERNAL_SERVER_ERROR;
        }

        return defaultGoogleGroups;
    }

    # Get public google groups. These are the google groups that the user can subscribe to and unsubscribe from.
    #
    # + return - public google groups as a string array
    resource function get public\-google\-groups(http:RequestContext ctx)
        returns string[]|http:Unauthorized|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            log:printError(USER_INFO_HEADER_NOT_FOUND_ERROR, userInfo);
            return <http:InternalServerError>{
                body: {
                    message: USER_INFO_HEADER_NOT_FOUND_ERROR
                }
            };
        }

        string[]|error publicGoogleGroups = google_sdk:getUserSubscribableGroups();
        if publicGoogleGroups is error {
            log:printError(string `Error in getting public google groups`, 'error = publicGoogleGroups,
                    stackTrace = publicGoogleGroups.stackTrace(), userEmail = userInfo.email);
            return http:INTERNAL_SERVER_ERROR;
        }

        return publicGoogleGroups;
    }

    # Get user subscribed private google groups. These are the private google groups that the user is subscribed to.
    #
    # + return - user subscribed private google groups as a string array
    resource function get private\-google\-groups(http:RequestContext ctx)
        returns string[]|http:Unauthorized|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            log:printError(USER_INFO_HEADER_NOT_FOUND_ERROR, userInfo);
            return <http:InternalServerError>{
                body: {
                    message: USER_INFO_HEADER_NOT_FOUND_ERROR
                }
            };
        }

        string[]|error userSubscribedPrivateGroups = google_sdk:getUserSubscribedPrivateGroups(userInfo.email);
        if userSubscribedPrivateGroups is error {
            log:printError(string `Error in getting private google groups`, 'error = userSubscribedPrivateGroups,
                    stackTrace = userSubscribedPrivateGroups.stackTrace(), userEmail = userInfo.email);
            return http:INTERNAL_SERVER_ERROR;
        }

        return userSubscribedPrivateGroups;
    }

    # Get user google groups. These are the google groups that the user is subscribed to.
    #
    # + return - user's google groups as a string array
    resource function get user\-google\-groups(http:RequestContext ctx)
        returns string[]|http:Unauthorized|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            log:printError(USER_INFO_HEADER_NOT_FOUND_ERROR, userInfo);
            return <http:InternalServerError>{
                body: {
                    message: USER_INFO_HEADER_NOT_FOUND_ERROR
                }
            };
        }

        google_sdk:Group[]|error userGoogleGroups = google_sdk:getGroupsForUser(userInfo.email);
        if userGoogleGroups is error {
            log:printError(string `Error in getting user's google groups`, 'error = userGoogleGroups,
                    stackTrace = userGoogleGroups.stackTrace(), userEmail = userInfo.email);
            return http:INTERNAL_SERVER_ERROR;
        }

        string[] userGoogleGroupEmails = [];
        foreach google_sdk:Group group in userGoogleGroups {
            userGoogleGroupEmails.push(group.email);
        }

        return userGoogleGroupEmails;
    }

    # Get all google groups. These are the all available google groups that the user can subscribe to and unsubscribe from.
    #
    # + return - all google groups as a string array
    resource function get all\-google\-groups(http:RequestContext ctx)
        returns string[]|http:Unauthorized|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            log:printError(USER_INFO_HEADER_NOT_FOUND_ERROR, userInfo);
            return <http:InternalServerError>{
                body: {
                    message: USER_INFO_HEADER_NOT_FOUND_ERROR
                }
            };
        }

        string[]|error allGoogleGroups = google_sdk:getAllGroupsInDomain(utils:emailDomain);
        if allGoogleGroups is error {
            log:printError(string `Error in getting all google groups`, 'error = allGoogleGroups,
                    stackTrace = allGoogleGroups.stackTrace(), userEmail = userInfo.email);
            return http:INTERNAL_SERVER_ERROR;
        }

        return allGoogleGroups;
    }

    # Subscribe the user to a google group.
    #
    # + input - types:Subscription
    # + return - http:Ok|http:Unauthorized|http:InternalServerError|http:BadRequest
    resource function patch google\-group/subscribe(http:RequestContext ctx,
            @http:Payload types:Subscription input) returns http:Ok|http:Unauthorized|http:InternalServerError|http:BadRequest {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            log:printError(USER_INFO_HEADER_NOT_FOUND_ERROR, userInfo);
            return <http:InternalServerError>{
                body: {
                    message: USER_INFO_HEADER_NOT_FOUND_ERROR
                }
            };
        }

        string groupEmail = utils:createGroupEmailFromGroupName(input.groupName);
        boolean|error res = google_sdk:checkGroupIsSubscribable(groupEmail);
        if res is error {
            log:printError(string `Error checking if the group is subscribable: ${input.groupName}`, 'error = res,
                    stackTrace = res.stackTrace(), userEmail = userInfo.email);
            return http:INTERNAL_SERVER_ERROR;
        }

        if res == false {
            log:printInfo(string `The group is not subscribable: ${input.groupName}`, userEmail = userInfo.email);
            return http:BAD_REQUEST;
        }

        boolean|error response = google_sdk:subscribeUserToGroup(userInfo.email, groupEmail);
        if response is error {
            log:printError(string `Error when subscribing to the google group: ${input.groupName}`, 'error = response,
                    stackTrace = response.stackTrace(), userEmail = userInfo.email);
            return http:INTERNAL_SERVER_ERROR;
        }

        log:printInfo(string `Successfully subscribed to the google group: ${input.groupName}`,
                userEmail = userInfo.email);

        return http:OK;
    }

    # Unsubscribe the user from a google group.
    #
    # + input - types:Subscription
    # + return - http:Ok|http:Unauthorized|http:InternalServerError
    resource function patch google\-group/unsubscribe(http:RequestContext ctx,
            @http:Payload types:Subscription input) returns http:Ok|http:Unauthorized|http:InternalServerError {

        authorization:CustomJwtPayload|error userInfo = ctx.getWithType(authorization:HEADER_USER_INFO);
        if userInfo is error {
            log:printError(USER_INFO_HEADER_NOT_FOUND_ERROR, userInfo);
            return <http:InternalServerError>{
                body: {
                    message: USER_INFO_HEADER_NOT_FOUND_ERROR
                }
            };
        }

        string groupEmail = utils:createGroupEmailFromGroupName(input.groupName);
        boolean|error response = google_sdk:unsubscribeUserFromGroup(userInfo.email, groupEmail);
        if response is error {
            log:printError(string `Error when unsubscribing from the google group: ${input.groupName}`, 'error = response,
                    stackTrace = response.stackTrace(), userEmail = userInfo.email);
            return http:INTERNAL_SERVER_ERROR;
        }

        log:printInfo(string `Successfully unsubscribed from the google group: ${input.groupName}`,
                userEmail = userInfo.email);

        return http:OK;
    }
}
