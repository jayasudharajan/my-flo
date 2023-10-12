import { Container } from 'inversify';
import _ from 'lodash';

function mergeContainers(container1, container2) {
  if (!container1) {
    return container2;
  }

  if(!container2) {
    return container1;
  }

  const container = new Container();
  const mergedDictionary = container._bindingDictionary;
  const bindingDictionary1 = container1._bindingDictionary;
  const bindingDictionary2 = container2._bindingDictionary;
  const identifiers1 = getServiceIdentifiers(bindingDictionary1);
  const identifiers2 = getServiceIdentifiers(bindingDictionary2);
  const blacklist = _.intersection(identifiers1, identifiers2);

  function getServiceIdentifiers(bindingDictionary) {
    const identifiers = [];

    bindingDictionary.traverse((key, value) => {
      value.forEach(binding => {
        identifiers.push(binding.serviceIdentifier);
      });
    });
    return identifiers;
  }

  function copyDictionary(origin, destination, blacklist) {
    origin.traverse(function (key, value) {
      value.forEach(function (binding) {
        if(!_.includes(blacklist, binding.serviceIdentifier)) {
          destination.add(binding.serviceIdentifier, binding.clone());
        }
      });
    });
  }
  copyDictionary(bindingDictionary1, mergedDictionary, blacklist);
  copyDictionary(bindingDictionary2, mergedDictionary);
  return container;
}

export default {
  mergeContainers: mergeContainers
}