// Copyright (c) 2026 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import {
  Box,
  Typography,
  CircularProgress,
  Container,
  Checkbox,
} from "@mui/material";
import { LoadingButton } from "@mui/lab";
import { useTheme, alpha } from "@mui/material/styles";
import SearchBar from "../component/SearchBar";
import SubscribeButton from "../component/SubscribeButton";
import ErrorHandler from "@component/common/ErrorHandler";
import { useState } from "react";
import { State } from "@root/src/types/types";
import NotFound from "./NotFound";
import { useAppDispatch, useAppSelector } from "@root/src/slices/store";
import { subscribeGroup } from "@slices/subscribeSlice/subscribe";
import { unsubscribeGroup } from "@slices/unsubscribeSlice/unsubscribe";
import {
  addNewGroup,
  removeExistingGroup,
} from "@root/src/slices/userGroupsSlice/userGroups";

type Props = {
  title: string;
  groups: string[];
  state: State;
  errorMessage: string | null;
  showSubscribe?: boolean;
  userGroups?: string[];
};

function GroupsList({
  title,
  groups,
  state,
  errorMessage,
  showSubscribe = false,
  userGroups = [],
}: Props) {
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedGroups, setSelectedGroups] = useState<string[]>([]);
  const [bulkSubscribeLoading, setBulkSubscribeLoading] = useState(false);
  const [bulkUnsubscribeLoading, setBulkUnsubscribeLoading] = useState(false);
  const theme = useTheme();
  const dispatch = useAppDispatch();
  const userEmail = useAppSelector((state) => state.auth.userInfo?.email);

  const filteredGroups = groups.filter((group) =>
    group.toLowerCase().includes(searchTerm.toLowerCase()),
  );

  const selectedSubscribedGroups = selectedGroups.filter((group) =>
    userGroups.includes(group),
  );
  const selectedUnsubscribedGroups = selectedGroups.filter(
    (group) => !userGroups.includes(group),
  );

  const toggleGroupSelection = (group: string) => {
    setSelectedGroups((prev) =>
      prev.includes(group)
        ? prev.filter((item) => item !== group)
        : [...prev, group],
    );
  };

  const clearSelection = () => {
    setSelectedGroups([]);
  };

  const handleBulkSubscribe = async () => {
    if (!userEmail || selectedUnsubscribedGroups.length === 0) {
      return;
    }

    try {
      setBulkSubscribeLoading(true);
      const results = await Promise.allSettled(
        selectedUnsubscribedGroups.map((group) =>
          dispatch(subscribeGroup(group)).unwrap(),
        ),
      );

      selectedUnsubscribedGroups.forEach((group, index) => {
        if (results[index].status === "fulfilled") {
          dispatch(addNewGroup(group));
        }
      });
    } finally {
      setBulkSubscribeLoading(false);
    }
  };

  const handleBulkUnsubscribe = async () => {
    if (!userEmail || selectedSubscribedGroups.length === 0) {
      return;
    }

    try {
      setBulkUnsubscribeLoading(true);
      const results = await Promise.allSettled(
        selectedSubscribedGroups.map((group) =>
          dispatch(unsubscribeGroup(group)).unwrap(),
        ),
      );

      selectedSubscribedGroups.forEach((group, index) => {
        if (results[index].status === "fulfilled") {
          dispatch(removeExistingGroup(group));
        }
      });
    } finally {
      setBulkUnsubscribeLoading(false);
    }
  };

  if (state === State.loading)
    return (
      <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}>
        <CircularProgress />
      </Box>
    );

  if (state === State.failed) return <ErrorHandler message={errorMessage} />;

  return (
    <Container>
      {/* Search */}
      <Box sx={{ mb: 3 }}>
        <SearchBar
          placeholder={`Search ${title}...`}
          onQueryChange={setSearchTerm}
        />
      </Box>

      {showSubscribe && (
        <Box
          sx={{
            mb: 3,
            display: "flex",
            alignItems: "center",
            justifyContent: "flex-end",
            flexWrap: "wrap",
            gap: 1.5,
          }}
        >
          <LoadingButton
            variant="outlined"
            onClick={clearSelection}
            disabled={selectedGroups.length === 0}
          >
            Clear All Selections ({selectedGroups.length})
          </LoadingButton>

          <LoadingButton
            variant="contained"
            color="primary"
            onClick={handleBulkSubscribe}
            loading={bulkSubscribeLoading}
            disabled={selectedUnsubscribedGroups.length === 0}
          >
            Subscribe ({selectedUnsubscribedGroups.length})
          </LoadingButton>

          <LoadingButton
            variant="contained"
            color="error"
            onClick={handleBulkUnsubscribe}
            loading={bulkUnsubscribeLoading}
            disabled={selectedSubscribedGroups.length === 0}
          >
            Unsubscribe ({selectedSubscribedGroups.length})
          </LoadingButton>
        </Box>
      )}

      {/* GRID */}
      <Box
        sx={{
          display: "grid",
          gridTemplateColumns: {
            xs: "1fr",
            sm: "1fr 1fr",
            md: "1fr 1fr 1fr",
          },
          gap: 2,
        }}
      >
        {filteredGroups.length === 0 && (
          <Box
            sx={{
              gridColumn: "1 / -1",
              display: "flex",
              justifyContent: "center",
              alignItems: "center",
              height: "50vh",
            }}
          >
            <NotFound message={`No ${title} found`} />
          </Box>
        )}
        {filteredGroups.map((group) => (
          <Box
            key={group}
            sx={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",

              border: `1px solid ${theme.palette.divider}`,
              p: 1,
              px: 2,
              minHeight: 40,

              backgroundColor: alpha(theme.palette.background.paper, 0.6),

              transition: "0.2s",

              "&:hover": {
                boxShadow:
                  theme.palette.mode === "light"
                    ? "0 2px 8px rgba(0,0,0,0.1)"
                    : "0 2px 8px rgba(0,0,0,0.6)",
              },
            }}
          >
            <Box sx={{ display: "flex", alignItems: "center", gap: 1 }}>
              {showSubscribe && (
                <Checkbox
                  checked={selectedGroups.includes(group)}
                  onChange={() => toggleGroupSelection(group)}
                />
              )}

              {/* TEXT */}
              <Typography
                sx={{
                  fontSize: "14px",
                  wordBreak: "break-all",
                  color: theme.palette.text.primary,
                }}
              >
                {group}
              </Typography>
            </Box>

            {/* BUTTON */}
            {showSubscribe && (
              <SubscribeButton
                groupEmail={group}
                isSubscribed={userGroups.includes(group)}
              />
            )}
          </Box>
        ))}
      </Box>
    </Container>
  );
}

export default GroupsList;
