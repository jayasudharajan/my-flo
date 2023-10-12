import _ from 'lodash';
import DIFactory from  '../../../../util/DIFactory';
import LocationProvider from './LocationProvider';
import UserProvider from './UserProvider';
import AccountProvider from './AccountProvider';
import IFTTTProvider from './IFTTTProvider';

class SubResourceProviderFactory {
  constructor(...subResourceProviders) {
    this.subResourceProviders = subResourceProviders;
  }

  getSubResourceProvider(resourceName, retrieveBy, params, tokenMetadata) {
    const provider = _.find(this.subResourceProviders, { resourceName });

    return (
      provider && 
      provider[retrieveBy] &&
      ((...args) => provider[retrieveBy](params, tokenMetadata, ...args))
    );
  }
}

export default new DIFactory(SubResourceProviderFactory, [
  LocationProvider,
  UserProvider,
  AccountProvider,
  IFTTTProvider
]);