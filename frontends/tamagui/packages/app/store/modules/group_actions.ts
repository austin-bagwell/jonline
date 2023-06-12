import { EventListingType, GetEventsResponse, GetGroupPostsRequest, GetGroupPostsResponse, GetGroupsRequest, GetGroupsResponse, GetPostsResponse, Group, GroupPost, PostListingType } from "@jonline/api";

import {
  AsyncThunk,
  createAsyncThunk
} from "@reduxjs/toolkit";
import { AccountOrServer, getCredentialClient } from "..";

export type CreateGroup = AccountOrServer & Group;
export const createGroup: AsyncThunk<Group, CreateGroup, any> = createAsyncThunk<Group, CreateGroup>(
  "groups/create",
  async (createGroupRequest) => {
    const client = await getCredentialClient(createGroupRequest);
    return client.createGroup(createGroupRequest, client.credential);
  }
);

export type UpdateGroups = AccountOrServer & GetGroupsRequest;
export const updateGroups: AsyncThunk<GetGroupsResponse, UpdateGroups, any> = createAsyncThunk<GetGroupsResponse, UpdateGroups>(
  "groups/update",
  async (getGroupsRequest) => {
    const client = await getCredentialClient(getGroupsRequest);
    return await client.getGroups(getGroupsRequest, client.credential);
  }
);

export type LoadGroupPostsPage = AccountOrServer & { groupId: string, page?: number };
export const loadGroupPostsPage: AsyncThunk<GetPostsResponse, LoadGroupPostsPage, any> = createAsyncThunk<GetPostsResponse, LoadGroupPostsPage>(
  "groups/loadPostsPage",
  async (request) => {
    const { groupId } = request;
    const client = await getCredentialClient(request);
    const result = await client.getPosts({ groupId, listingType: PostListingType.GROUP_POSTS }, client.credential);
    return result;
  }
);

export type LoadGroupEventsPage = AccountOrServer & { groupId: string, page?: number };
export const loadGroupEventsPage: AsyncThunk<GetEventsResponse, LoadGroupEventsPage, any> = createAsyncThunk<GetEventsResponse, LoadGroupEventsPage>(
  "groups/loadEventsPage",
  async (request) => {
    const { groupId } = request;
    const client = await getCredentialClient(request);
    const result = await client.getEvents({ groupId, listingType: EventListingType.GROUP_EVENTS }, client.credential);
    return result;
  }
);

export type LoadGroup = { id: string } & AccountOrServer;
export const loadGroup: AsyncThunk<Group, LoadGroup, any> = createAsyncThunk<Group, LoadGroup>(
  "groups/loadOne",
  async (request) => {
    const client = await getCredentialClient(request);
    const response = await client.getGroups(GetGroupsRequest.create({ groupId: request.id }), client.credential);
    const group = response.groups[0]!;
    return group;
  }
);

export type LoadGroupPostsForPost = AccountOrServer & {
  postId: string,
};

export const loadGroupPostsForPost: AsyncThunk<GetGroupPostsResponse, LoadGroupPostsForPost, any> = createAsyncThunk<GetGroupPostsResponse, LoadGroupPostsForPost>(
  "groups/loadGroupPostsForPost",
  async (request) => {
    const { postId } = request;
    const client = await getCredentialClient(request);
    const result = await client.getGroupPosts({ postId }, client.credential);
    return result;
  }
);

export type CreateGroupPost = AccountOrServer & { groupId: string, postId: string };
export const createGroupPost: AsyncThunk<GroupPost, CreateGroupPost, any> = createAsyncThunk<GroupPost, CreateGroupPost>(
  'groups/createGroupPost',
  async (request) => {
    const { groupId, postId } = request;
    const client = await getCredentialClient(request);
    const result = await client.createGroupPost({ groupId, postId }, client.credential);
    return result;
  }
);