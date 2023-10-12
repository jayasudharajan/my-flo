import ClientType from '../../util/ClientType';

function mapToUsedApp(req) {
  const userAgent = (req.headers['user-agent'] || '').toLowerCase();
  const origin = (req.headers['origin'] || '').split('//')[1] || '';

  if (userAgent.startsWith('flo-ios')) {
    return ClientType.IPHONE;
  } else if (userAgent.startsWith('flo-android')) {
    return ClientType.ANDROID_PHONE;
  } else if (origin.startsWith('user')) {
    return ClientType.USER_PORTAL;
  } else if (origin.startsWith('admin')) {
    return ClientType.ADMIN_SITE;
  } else {
    return ClientType.OTHER;
  }
}

function addAppUsed(req, res, next) {
  req.app_used = mapToUsedApp(req);
  next();
}

export default addAppUsed;
