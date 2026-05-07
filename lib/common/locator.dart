import 'package:get_it/get_it.dart';
import 'package:nchat_mobile/common/application.dart';
import 'package:nchat_mobile/common/authentication.dart';
import 'package:nchat_mobile/common/broadcast/avatar_broadcast.dart';
import 'package:nchat_mobile/common/chat/chat.dart';
import 'package:nchat_mobile/common/chat/chat_in.dart';
import 'package:nchat_mobile/common/chat/chat_out.dart';
import 'package:nchat_mobile/common/client/client.dart';
import 'package:nchat_mobile/common/contact/contact.dart';
import 'package:nchat_mobile/common/contact/device_info.dart';
import 'package:nchat_mobile/common/db/db.dart';
import 'package:nchat_mobile/common/discovery/public_group_discovery.dart';
import 'package:nchat_mobile/common/message/message.dart';
import 'package:nchat_mobile/common/message/session.dart';
import 'package:nchat_mobile/common/private_group/private_group.dart';
import 'package:nchat_mobile/common/push/local_notification.dart';
import 'package:nchat_mobile/common/topic/subscriber.dart';
import 'package:nchat_mobile/common/topic/topic.dart';
import 'package:nchat_mobile/common/wallet/wallet.dart';
import 'package:nchat_mobile/helpers/audio.dart';
import 'package:nchat_mobile/helpers/ipfs.dart';
import 'package:nchat_mobile/helpers/memory_cache.dart';
import 'package:nchat_mobile/services/avatar_cache_service.dart';
import 'package:nchat_mobile/services/task.dart';

GetIt locator = GetIt.instance;

late Application application;
late TaskService taskService;
late Authorization authorization;
late LocalNotification localNotification;
// late BackgroundFetchService backgroundFetchService;
late AudioHelper audioHelper;
late IpfsHelper ipfsHelper;
late MemoryCache memoryCache;
late PublicGroupDiscoveryService discoveryService;
late AvatarBroadcastService avatarBroadcastService;
late AvatarCacheService avatarCacheService;

late DB dbCommon;
late WalletCommon walletCommon;
late ClientCommon clientCommon;
late MessageCommon messageCommon;
late SessionCommon sessionCommon;
late ChatCommon chatCommon;
late ChatInCommon chatInCommon;
late ChatOutCommon chatOutCommon;
late ContactCommon contactCommon;
late DeviceInfoCommon deviceInfoCommon;
late TopicCommon topicCommon;
late SubscriberCommon subscriberCommon;
late PrivateGroupCommon privateGroupCommon;

void setupLocator() {
  // register
  locator.registerSingleton(Application());
  locator.registerSingleton(TaskService());
  locator.registerSingleton(Authorization());
  locator.registerSingleton(LocalNotification());
  locator.registerSingleton(PublicGroupDiscoveryService());
  locator.registerSingleton(AvatarBroadcastService());
  locator.registerSingleton(AvatarCacheService());
  // locator.registerSingleton(BackgroundFetchService());
  locator.registerSingleton(AudioHelper());
  locator.registerSingleton(IpfsHelper());
  locator.registerSingleton(MemoryCache());

  locator.registerSingleton(DB());
  locator.registerSingleton(WalletCommon());
  locator.registerSingleton(ClientCommon());
  locator.registerSingleton(MessageCommon());
  locator.registerSingleton(SessionCommon());
  locator.registerSingleton(ChatCommon());
  locator.registerSingleton(ChatInCommon());
  locator.registerSingleton(ChatOutCommon());
  locator.registerSingleton(ContactCommon());
  locator.registerSingleton(DeviceInfoCommon());
  locator.registerSingleton(TopicCommon());
  locator.registerSingleton(SubscriberCommon());
  locator.registerSingleton(PrivateGroupCommon());

  // instance
  application = locator.get<Application>();
  taskService = locator.get<TaskService>();
  authorization = locator.get<Authorization>();
  localNotification = locator.get<LocalNotification>();
  discoveryService = locator.get<PublicGroupDiscoveryService>();
  avatarBroadcastService = locator.get<AvatarBroadcastService>();
  avatarCacheService = locator.get<AvatarCacheService>();
  // backgroundFetchService = locator.get<BackgroundFetchService>();
  audioHelper = locator.get<AudioHelper>();
  ipfsHelper = locator.get<IpfsHelper>();
  memoryCache = locator.get<MemoryCache>();

  dbCommon = locator.get<DB>();
  walletCommon = locator.get<WalletCommon>();
  clientCommon = locator.get<ClientCommon>();
  messageCommon = locator.get<MessageCommon>();
  sessionCommon = locator.get<SessionCommon>();
  chatCommon = locator.get<ChatCommon>();
  chatInCommon = locator.get<ChatInCommon>();
  chatOutCommon = locator.get<ChatOutCommon>();
  contactCommon = locator.get<ContactCommon>();
  deviceInfoCommon = locator.get<DeviceInfoCommon>();
  topicCommon = locator.get<TopicCommon>();
  subscriberCommon = locator.get<SubscriberCommon>();
  privateGroupCommon = locator.get<PrivateGroupCommon>();
}
