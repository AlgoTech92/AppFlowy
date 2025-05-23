import 'dart:async';

import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:fixnum/fixnum.dart' as fixnum;

class WorkspaceService {
  WorkspaceService({required this.workspaceId, required this.userId});

  final String workspaceId;
  final fixnum.Int64 userId;

  Future<FlowyResult<ViewPB, FlowyError>> createView({
    required String name,
    required ViewSectionPB viewSection,
    int? index,
    ViewLayoutPB? layout,
    bool? setAsCurrent,
    String? viewId,
    String? extra,
  }) {
    final payload = CreateViewPayloadPB.create()
      ..parentViewId = workspaceId
      ..name = name
      ..layout = layout ?? ViewLayoutPB.Document
      ..section = viewSection;

    if (index != null) {
      payload.index = index;
    }

    if (setAsCurrent != null) {
      payload.setAsCurrent = setAsCurrent;
    }

    if (viewId != null) {
      payload.viewId = viewId;
    }

    if (extra != null) {
      payload.extra = extra;
    }

    return FolderEventCreateView(payload).send();
  }

  Future<FlowyResult<WorkspacePB, FlowyError>> getWorkspace() {
    return FolderEventReadCurrentWorkspace().send();
  }

  Future<FlowyResult<List<ViewPB>, FlowyError>> getPublicViews() {
    final payload = GetWorkspaceViewPB.create()..value = workspaceId;
    return FolderEventReadWorkspaceViews(payload).send().then((result) {
      return result.fold(
        (views) => FlowyResult.success(views.items),
        (error) => FlowyResult.failure(error),
      );
    });
  }

  Future<FlowyResult<List<ViewPB>, FlowyError>> getPrivateViews() {
    final payload = GetWorkspaceViewPB.create()..value = workspaceId;
    return FolderEventReadPrivateViews(payload).send().then((result) {
      return result.fold(
        (views) => FlowyResult.success(views.items),
        (error) => FlowyResult.failure(error),
      );
    });
  }

  Future<FlowyResult<void, FlowyError>> moveView({
    required String viewId,
    required int fromIndex,
    required int toIndex,
  }) {
    final payload = MoveViewPayloadPB.create()
      ..viewId = viewId
      ..from = fromIndex
      ..to = toIndex;

    return FolderEventMoveView(payload).send();
  }

  Future<FlowyResult<WorkspaceUsagePB?, FlowyError>> getWorkspaceUsage() async {
    final request = WorkspaceMemberIdPB()..uid = userId;
    final result = await UserEventGetMemberInfo(request).send();
    final isOwner = result.fold(
      (member) => member.role.isOwner,
      (_) => false,
    );

    if (!isOwner) {
      return FlowyResult.success(null);
    }

    final payload = UserWorkspaceIdPB(workspaceId: workspaceId);
    return UserEventGetWorkspaceUsage(payload).send();
  }

  Future<FlowyResult<BillingPortalPB, FlowyError>> getBillingPortal() {
    return UserEventGetBillingPortal().send();
  }
}
