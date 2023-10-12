import ClientType from './ClientType';
import {EventData, Icd} from '../interfaces';
import {Pinpoint} from "aws-sdk";

const ChannelType = {
  GCM: 'GCM',
  APNS: 'APNS'
};

export default function generateInstalledPushMessage(eventData: EventData): Pinpoint.Types.MessageRequest | null {
  const { clientType, token, device } = eventData;
  const channelType = getChannelType(clientType);

  if(channelType) {
    return {
      Addresses: {
        [token]: {
          ChannelType: channelType
        }
      },
      MessageConfiguration: {
        [channelType + 'Message']: getPlatformMessage(channelType, device)
      }
    };
  }

  return null;
};

function getChannelType(clientType: number) {
  if (clientType == ClientType.ANDROID_PHONE || clientType == ClientType.ANDROID_TABLET) {
    return ChannelType.GCM;
  } else if (clientType == ClientType.I_PAD || clientType == ClientType.I_PHONE) {
    return ChannelType.APNS;
  }

  return null;
}

function getPlatformMessage(channelType: string, device: Icd) {
  if(channelType == ChannelType.GCM) {
    return {
      RawContent: `{
        "data": {
          "url": "floapp://needs_install",
          "data": {
            "deviceId": "${device.id}",
            "nickname": "${device.nickname}"
          }
        }
      }`
    };
  } else {
    // TODO: Make the alert message come from the Localization Service
    return {
      RawContent: `{
        "aps": {
          "alert": "Device installed",
          "sound": "default",
          "category": {
            "DeviceInstalledNotification": {
              "deviceId": "${device.id}",
              "nickname": "${device.nickname}"
            }
          }
        }
      }`
    };
  }
}
