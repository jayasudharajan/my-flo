export default class SubResourceProvider {
  constructor(resourceName) {
    this.resourceName = resourceName;
  }

  formatSubResource(subResourceId) {
    return `${ this.resourceName }.${ subResourceId }`;
  }
}