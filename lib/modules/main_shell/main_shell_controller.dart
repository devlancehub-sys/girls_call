import 'package:get/get.dart';

import '../../core/messaging/fcm_payload_mapper.dart';
import '../../core/services/host_availability_service.dart';
import '../../core/services/socket_service.dart';
import '../../routes/app_routes.dart';
import '../active_call/active_call_controller.dart';
import '../incoming_call/incoming_call_controller.dart';
import '../online_users/online_users_controller.dart';

class MainShellController extends GetxController {
  final SocketService _socket = Get.find<SocketService>();

  final currentIndex = 0.obs;

  final _titles = ['Dashboard', 'Online Users', 'Profile'];

  String get currentTitle => _titles[currentIndex.value];

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 1 && Get.isRegistered<OnlineUsersController>()) {
      Get.find<OnlineUsersController>().loadUsers();
    }
  }

  @override
  void onInit() {
    super.onInit();
    _listenIncomingCalls();
    if (Get.isRegistered<HostAvailabilityService>()) {
      Get.find<HostAvailabilityService>().listenSocketEvents();
    }
    _socket.onUserPresenceChanged = _refreshUsers;
  }

  void _refreshUsers() {
    if (Get.isRegistered<OnlineUsersController>()) {
      Get.find<OnlineUsersController>().loadUsers();
    }
  }

  void _listenIncomingCalls() {
    _socket.onIncomingCall = (data) {
      print('[Call Lifecycle] incoming_call event received. ActiveCallController active: ${ActiveCallController.active}, IncomingCallController active: ${IncomingCallController.active}');
      if (ActiveCallController.active || IncomingCallController.active) {
        print('[Call Lifecycle] Blocked incoming call screen navigation: Host is busy.');
        return;
      }
      Get.toNamed(
        AppRoutes.incomingCall,
        arguments: FcmPayloadMapper.toCallArguments(data),
      );
    };
  }

  @override
  void onClose() {
    _socket.onIncomingCall = null;
    _socket.onUserPresenceChanged = null;
    if (Get.isRegistered<HostAvailabilityService>()) {
      Get.find<HostAvailabilityService>().stopListening();
    }
    super.onClose();
  }
}
