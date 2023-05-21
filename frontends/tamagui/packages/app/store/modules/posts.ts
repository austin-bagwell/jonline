import { Post, PostListingType } from "@jonline/api";
import { formatError } from "@jonline/ui";
import {
  createEntityAdapter,
  createSlice,
  Dictionary,
  Draft,
  EntityAdapter,
  EntityId, Slice
} from "@reduxjs/toolkit";
import moment from "moment";
import { loadGroupPosts } from "./groups";
import { createPost, defaultPostListingType, LoadPost, loadPost, loadPostReplies, loadPostsPage, replyToPost } from './post_actions';
import { loadUserPosts } from "./users";
import { Visibility } from '../../../api/generated/visibility_moderation';
import { publicVisibility } from "app/utils/visibility";
export * from './post_actions';

export interface PostsState {
  baseStatus: "unloaded" | "loading" | "loaded" | "errored";
  status: "unloaded" | "loading" | "loaded" | "errored";
  sendReplyStatus?: "sending" | "sent" | "errored";
  createPostStatus?: "posting" | "posted" | "errored";
  error?: Error;
  successMessage?: string;
  errorMessage?: string;
  draftPost: DraftPost;
  ids: EntityId[];
  entities: Dictionary<Post>;
  // Stores pages of listed posts for listing types used in the UI.
  // i.e.: postPages[PostListingType.PUBLIC_POSTS][0] -> ["postId1", "postId2"].
  // Posts should be loaded from the adapter/slice's entities.
  // Maps PostListingType -> page -> postIds
  postPages: Dictionary<Dictionary<string[]>>;
  failedPostIds: string[];
}

export interface DraftPost {
  newPost: Post;
  groupId?: string;
}

const postsAdapter: EntityAdapter<Post> = createEntityAdapter<Post>({
  selectId: (post) => post.id,
  sortComparer: (a, b) => moment.utc(b.createdAt).unix() - moment.utc(a.createdAt).unix(),
});

const initialState: PostsState = {
  status: "unloaded",
  baseStatus: "unloaded",
  draftPost: {
    newPost: Post.fromPartial({})
  },
  sendReplyStatus: undefined,
  failedPostIds: [],
  postPages: {},
  ...postsAdapter.getInitialState(),
};

export const postsSlice: Slice<Draft<PostsState>, any, "posts"> = createSlice({
  name: "posts",
  initialState: initialState,
  reducers: {
    upsertPost: postsAdapter.upsertOne,
    removePost: postsAdapter.removeOne,
    resetPosts: () => initialState,
    clearPostAlerts: (state) => {
      state.errorMessage = undefined;
      state.successMessage = undefined;
      state.error = undefined;
      state.createPostStatus = undefined;
      state.sendReplyStatus = undefined;
    },
    confirmReplySent: (state) => {
      state.sendReplyStatus = undefined;
    },
  },
  extraReducers: (builder) => {
    builder.addCase(createPost.pending, (state) => {
      state.status = "loading";
      state.createPostStatus = "posting";
      state.error = undefined;
    });
    builder.addCase(createPost.fulfilled, (state, action) => {
      state.status = "loaded";
      state.createPostStatus = "posted";
      postsAdapter.upsertOne(state, action.payload);
      if (publicVisibility(action.payload.visibility)) {
        state.postPages[defaultPostListingType] = state.postPages[defaultPostListingType] || {};
        const firstPage = state.postPages[defaultPostListingType][0] || [];
        state.postPages[defaultPostListingType][0] = [action.payload.id, ...firstPage];
      }
      state.successMessage = `Post created.`;
    });
    builder.addCase(createPost.rejected, (state, action) => {
      state.status = "errored";
      state.createPostStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(replyToPost.pending, (state) => {
      state.sendReplyStatus = "sending";
      state.error = undefined;
    });
    builder.addCase(replyToPost.fulfilled, (state, action) => {
      state.sendReplyStatus = "sent";
      // postsAdapter.upsertOne(state, action.payload);
      const reply = action.payload;
      const postIdPath = action.meta.arg.postIdPath;
      const basePost = postsAdapter.getSelectors().selectById(state, postIdPath[0]!);
      if (!basePost) {
        console.error(`Root post ID (${postIdPath[0]}) not found.`);
        return;
      }
      const rootPost: Post = { ...basePost }

      let parentPost: Post = rootPost;
      for (const postId of postIdPath.slice(1)) {
        parentPost.replies = parentPost.replies.map(p => ({ ...p }));
        const nextPost = parentPost.replies.find((reply) => reply.id === postId);
        if (!nextPost) {
          console.error(`Post ID (${postId}) not found along path ${JSON.stringify(postIdPath)}.`);
          return;
        }
        parentPost = nextPost;
      }
      parentPost.replies = [reply].concat(...parentPost.replies);
      postsAdapter.upsertOne(state, rootPost);
      state.successMessage = `Reply created.`;
    });
    builder.addCase(replyToPost.rejected, (state, action) => {
      state.sendReplyStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(loadPostsPage.pending, (state) => {
      state.status = "loading";
      state.baseStatus = "loading";
      state.error = undefined;
    });
    builder.addCase(loadPostsPage.fulfilled, (state, action) => {
      state.status = "loaded";
      state.baseStatus = "loaded";
      action.payload.posts.forEach(post => {
        const oldPost = selectPostById(state, post.id);
        postsAdapter.upsertOne(state, { ...post, replies: oldPost?.replies ?? post.replies });
      });

      const postIds = action.payload.posts.map(post => post.id);
      const page = action.meta.arg.page || 0;
      const listingType = action.meta.arg.listingType ?? defaultPostListingType;

      if (!state.postPages[listingType] || page === 0) state.postPages[listingType] = {};
      const postPages: Dictionary<string[]> = state.postPages[listingType]!;
      // Sensible approach:
      // state.postPages[listingType]![page] = postIds;

      // Chunking approach: (note that we re-initialize `postPages` when `page` == 0)
      let initialPage: number = 0;
      while (postPages[initialPage]) {
        initialPage++;
      }
      const chunkSize = 10;
      let chunkNumber = 0;
      for (let i = 0; i < postIds.length; i += chunkSize) {
        const chunk = postIds.slice(i, i + chunkSize);
        state.postPages[listingType]![initialPage + chunkNumber++] = chunk;
      }

      state.successMessage = `Posts loaded.`;
    });
    builder.addCase(loadPostsPage.rejected, (state, action) => {
      state.status = "errored";
      state.baseStatus = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
    });
    builder.addCase(loadPost.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(loadPost.fulfilled, (state, action) => {
      state.status = "loaded";
      const oldPost = selectPostById(state, action.payload.id);
      postsAdapter.upsertOne(state, { ...action.payload, replies: oldPost?.replies ?? action.payload.replies });
      state.successMessage = `Post data loaded.`;
    });
    builder.addCase(loadPost.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = formatError(action.error as Error);
      state.error = action.error as Error;
      state.failedPostIds = [...state.failedPostIds, (action.meta.arg as LoadPost).id];
    });
    builder.addCase(loadPostReplies.pending, (state) => {
      state.status = "loading";
      state.error = undefined;
    });
    builder.addCase(loadPostReplies.fulfilled, (state, action) => {
      state.status = "loaded";
      // Load the replies into the post tree.
      const postIdPath = action.meta.arg.postIdPath;
      const basePost = postsAdapter.getSelectors().selectById(state, postIdPath[0]!);
      if (!basePost) {
        console.error(`Root post ID (${postIdPath[0]}) not found.`);
        return;
      }
      const rootPost: Post = { ...basePost }

      let post: Post = rootPost;
      for (const postId of postIdPath.slice(1)) {
        post.replies = post.replies.map(p => ({ ...p }));
        const nextPost = post.replies.find((reply) => reply.id === postId);
        if (!nextPost) {
          console.error(`Post ID (${postId}) not found along path ${JSON.stringify(postIdPath)}.`);
          return;
        }
        post = nextPost;
      }
      const mergedReplies = action.payload.posts.map(reply => {
        const oldReply = post.replies.find(r => r.id === reply.id);
        return { ...reply, replies: oldReply?.replies ?? reply.replies };
      });
      post.replies = mergedReplies;
      postsAdapter.upsertOne(state, rootPost);
      state.successMessage = `Replies loaded.`;
    });
    builder.addCase(loadPostReplies.rejected, (state, action) => {
      state.status = "errored";
      state.error = action.error as Error;
      state.errorMessage = `Error loading replies: ${formatError(action.error as Error)}`;
      state.error = action.error as Error;
    });

    builder.addCase(loadUserPosts.fulfilled, (state, action) => {
      const { posts } = action.payload;
      upsertPosts(state, posts);
    });
    builder.addCase(loadGroupPosts.fulfilled, (state, action) => {
      const { posts } = action.payload;
      upsertPosts(state, posts);
    });
  },
});

export const { removePost, clearPostAlerts: clearPostAlerts, confirmReplySent, resetPosts } = postsSlice.actions;
export const { selectAll: selectAllPosts, selectById: selectPostById } = postsAdapter.getSelectors();
export const postsReducer = postsSlice.reducer;
export const upsertPost = postsAdapter.upsertOne;
export const upsertPosts = postsAdapter.upsertMany;
export default postsReducer;

export function getPostsPage(state: PostsState, listingType: PostListingType, page: number): Post[] {
  const pagePostIds: string[] = (state.postPages[listingType] ?? {})[page] ?? [];
  const pagePosts = pagePostIds.map(id => selectPostById(state, id)).filter(p => p) as Post[];
  return pagePosts;
}

export function getPostPages(state: PostsState, listingType: PostListingType, throughPage: number): Post[] {
  const result: Post[] = [];
  // console.log('Page listing data' ,state.postPages[listingType]);
  for (let page = 0; page <= throughPage; page++) {
    const pagePostIds: string[] = (state.postPages[listingType] ?? {})[page] ?? [];
    const pagePosts = pagePostIds.map(id => selectPostById(state, id)).filter(p => p) as Post[];
    // console.log('Page posts', pagePosts);
    result.push(...pagePosts);
  }
  return result;
}
