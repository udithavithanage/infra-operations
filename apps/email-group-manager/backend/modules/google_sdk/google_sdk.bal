// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
//
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
// You may not alter or remove any copyright or other notice from copies of this content.

import ballerina/http;
import ballerina/url;

# Gets the groups a user is a member of using the Admin SDK API.
#
# + userEmail - The email of the user to get groups for
# + return - An array of Group records or an error if the API call fails
public isolated function getGroupsForUser(string userEmail) returns Group[]|error {
    string encodedUserEmail = check url:encode(userEmail, "UTF-8");
    string path = string `/admin/directory/v1/groups?userKey=${encodedUserEmail}`;
    http:Client adminClient = check getAdminClient();
    http:Response res = check adminClient->get(path);

    if res.statusCode != 200 {
        string errBody = check res.getTextPayload();
        return error(string `Admin SDK error ${res.statusCode}: ${errBody}`);
    }

    GroupListResponse groupPage = check (check res.getJsonPayload()).cloneWithType();
    return groupPage.groups ?: [];
}

# Gets the default groups for the default user.
#
# + return - An array of group email addresses or an error if the API call fails
public isolated function getDefaultGoogleGroups() returns string[]|error {
    Group[] defaultGroups = check getGroupsForUser(defaultUser);
    string[] defaultGroupEmails = [];
    foreach Group group in defaultGroups {
        defaultGroupEmails.push(group.email);
    }

    return defaultGroupEmails;
}

# Get the all groups in the domain.
#
# + emailDomain - The email domain to get groups for
# + return - An array of group email addresses or an error if the API call fails
public isolated function getAllGroupsInDomain(string emailDomain) returns string[]|error {
    string encodedEmailDomain = check url:encode(emailDomain, "UTF-8");
    string path = string `/admin/directory/v1/groups?domain=${encodedEmailDomain}`;
    http:Client adminClient = check getAdminClient();
    http:Response res = check adminClient->get(path);

    if res.statusCode != 200 {
        string errBody = check res.getTextPayload();
        return error(string `Admin SDK error ${res.statusCode}: ${errBody}`);
    }

    GroupListResponse groupPage = check (check res.getJsonPayload()).cloneWithType();
    string[] groupEmails = [];
    foreach Group group in groupPage.groups ?: [] {
        groupEmails.push(group.email);
    }

    return groupEmails;
}

# Gets the groups that the user can subscribe to.
#
# + return - An array of group email addresses or an error if the API call fails
public isolated function getUserSubscribableGroups() returns string[]|error {
    Group[] subscribableGroups = check getGroupsForUser(publicGroupUser);
    string[] subscribableGroupEmails = [];
    foreach Group group in subscribableGroups {
        subscribableGroupEmails.push(group.email);
    }

    return subscribableGroupEmails;
}

# Get given user subscribed private groups.
#
# + userEmail - The email of the user to get subscribed private groups for
# + return - An array of group email addresses or an error if the API call fails
public isolated function getUserSubscribedPrivateGroups(string userEmail) returns string[]|error {
    Group[] subscribedGroups = check getGroupsForUser(userEmail);
    Group[] privateGroups = check getGroupsForUser(publicGroupUser);
    string[] privateGroupEmails = [];
    foreach Group group in subscribedGroups {
        foreach Group privateGroup in privateGroups {
            if group.email == privateGroup.email {
                privateGroupEmails.push(group.email);
                break;
            }
        }
    }

    return privateGroupEmails;
}

# Subscribes a user to a group using the Admin SDK API.
#
# + userEmail - The email of the user to subscribe
# + groupEmail - The email of the group to subscribe the user to
# + return - true if the subscription was successful, or an error if the API call fails
public isolated function subscribeUserToGroup(string userEmail, string groupEmail) returns boolean|error {
    string encodedGroupEmail = check url:encode(groupEmail, "UTF-8");
    string path = string `/admin/directory/v1/groups/${encodedGroupEmail}/members`;
    Member member = {email: userEmail, role: "MEMBER"};
    http:Client adminClient = check getAdminClient();
    http:Response res = check adminClient->post(path, member);

    if res.statusCode != 200 {
        string errBody = check res.getTextPayload();
        return error(string `Admin SDK error ${res.statusCode}: ${errBody}`);
    }

    return true;
}

# Unsubscribes a user from a group using the Admin SDK API.
#
# + userEmail - The email of the user to unsubscribe
# + groupEmail - The email of the group to unsubscribe the user from
# + return - true if the unsubscription was successful, or an error if the API call fails
public isolated function unsubscribeUserFromGroup(string userEmail, string groupEmail) returns boolean|error {
    string encodedGroupEmail = check url:encode(groupEmail, "UTF-8");
    string encodedUserEmail = check url:encode(userEmail, "UTF-8");
    string path = string `/admin/directory/v1/groups/${encodedGroupEmail}/members/${encodedUserEmail}`;
    http:Client adminClient = check getAdminClient();
    http:Response res = check adminClient->delete(path);

    if res.statusCode != 200 && res.statusCode != 204 {
        string errBody = check res.getTextPayload();
        return error(string `Admin SDK error ${res.statusCode}: ${errBody}`);
    }

    return true;
}

# Checks if a group is subscribable by checking if the public group user is a member of the group.
#
# + groupEmail - The email of the group to check
# + return - true if the group is subscribable, false if not, or an error
public isolated function checkGroupIsSubscribable(string groupEmail) returns boolean|error {
    string encodedGroupEmail = check url:encode(groupEmail, "UTF-8");
    string path = string `/admin/directory/v1/groups/${encodedGroupEmail}/members/${publicGroupUser}`;
    http:Client adminClient = check getAdminClient();
    http:Response res = check adminClient->get(path);

    if res.statusCode == 200 {
        return true;
    } else if res.statusCode == 404 {
        return false;
    } else {
        string errBody = check res.getTextPayload();
        return error(string `Admin SDK error ${res.statusCode}: ${errBody}`);
    }
}
