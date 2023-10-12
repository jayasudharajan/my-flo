import { decorate, injectable, inject, named, optional } from 'inversify'
import reflect from 'reflect-metadata';

export default function DIFactory(injectableClass, injectArgs) {
	function Factory(...args) {
		return new injectableClass(...args);
	}

	Object.defineProperty(Factory, 'name', { get() { return injectableClass.name + 'Factory'; } });

	decorate(injectable(), Factory);

	injectArgs.forEach((injectArg, i) => {
		
		if (Array.isArray(injectArg)) {
			decorate(inject(injectArg[1]), Factory, i);
			decorate(named(injectArg[0]), Factory, i);
		} else if (injectArg.optional) {
			decorate(inject(injectArg.optional), Factory, i);
			decorate(optional(), Factory, i);
		} else {
			decorate(inject(injectArg), Factory, i);
		}
	});

	return Factory;
}