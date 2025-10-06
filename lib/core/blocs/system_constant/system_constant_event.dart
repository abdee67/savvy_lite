import 'package:equatable/equatable.dart';
import 'package:savvy_stock/core/models/system_constant.dart';

abstract class SystemConstantEvent extends Equatable {
  const SystemConstantEvent();

  @override
  List<Object> get props => [];
}

class LoadSystemConstants extends SystemConstantEvent {
  final int companyId;

  const LoadSystemConstants(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class LoadSystemConstant extends SystemConstantEvent {
  final int id;

  const LoadSystemConstant(this.id);

  @override
  List<Object> get props => [id];
}

class SyncSystemConstants extends SystemConstantEvent {
  const SyncSystemConstants();

  @override
  List<Object> get props => [];
}

class PullSystemConstants extends SystemConstantEvent {
  const PullSystemConstants();

  @override
  List<Object> get props => [];
}

class LoadSystemConstantsForCompany extends SystemConstantEvent {
  final int companyId;

  const LoadSystemConstantsForCompany(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class CreateSystemConstant extends SystemConstantEvent {
  final SystemConstant systemConstant;

  const CreateSystemConstant(this.systemConstant);

  @override
  List<Object> get props => [systemConstant];
}

class UpdateSystemConstant extends SystemConstantEvent {
  final SystemConstant systemConstant;

  const UpdateSystemConstant(this.systemConstant);

  @override
  List<Object> get props => [systemConstant];
}

class DeleteSystemConstant extends SystemConstantEvent {
  final SystemConstant systemConstant;

  const DeleteSystemConstant(this.systemConstant);

  @override
  List<Object> get props => [systemConstant];
}

class DeleteSystemConstants extends SystemConstantEvent {
  final List<SystemConstant> systemConstants;

  const DeleteSystemConstants(this.systemConstants);

  @override
  List<Object> get props => [systemConstants];
}

class PrepareCreate extends SystemConstantEvent {
  final int companyId;

  const PrepareCreate(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class PrepareCopy extends SystemConstantEvent {
  final SystemConstant systemConstant;
  final int companyId;

  const PrepareCopy(this.systemConstant, this.companyId);

  @override
  List<Object> get props => [systemConstant, companyId];
}

class PrepareEdit extends SystemConstantEvent {
  final int companyId;

  const PrepareEdit(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class CancelUpdate extends SystemConstantEvent {}

class CancelCreate extends SystemConstantEvent {}

class DiscardChanges extends SystemConstantEvent {}

class RemoveInCreate extends SystemConstantEvent {
  final SystemConstant systemConstant;

  const RemoveInCreate(this.systemConstant);

  @override
  List<Object> get props => [systemConstant];
}

class RemoveInEdit extends SystemConstantEvent {
  final SystemConstant systemConstant;

  const RemoveInEdit(this.systemConstant);

  @override
  List<Object> get props => [systemConstant];
}

class SaveSystemConstants extends SystemConstantEvent {
  final List<SystemConstant> systemConstants;

  const SaveSystemConstants(this.systemConstants);

  @override
  List<Object> get props => [systemConstants];
}

class SaveSystemConstantsForRegistration extends SystemConstantEvent {
  final List<SystemConstant> systemConstants;
  final int companyId;

  const SaveSystemConstantsForRegistration(
    this.systemConstants,
    this.companyId,
  );

  @override
  List<Object> get props => [systemConstants, companyId];
}

class SaveInEdit extends SystemConstantEvent {
  final List<SystemConstant> systemConstants;

  const SaveInEdit(this.systemConstants);

  @override
  List<Object> get props => [systemConstants];
}

class RetryFailedOperations extends SystemConstantEvent {
  const RetryFailedOperations();
}

class CheckConnectivity extends SystemConstantEvent {
  const CheckConnectivity();
}

class LoadUdcData extends SystemConstantEvent {
  const LoadUdcData();
}

class DebugSystemConstants extends SystemConstantEvent {
  const DebugSystemConstants();
}
