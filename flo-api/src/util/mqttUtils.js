import { getCerts } from './cert';
import mqtt from 'mqtt';
import config from '../config/config';

function getOptions() {
    return getCerts()
        .then(({ cert, key, ca }) => ({
            host: config.mqttBroker.host,
            port: config.mqttBroker.port,
            protocol: 'mqtts',
            qos:1,
            ca: ca,
            cert: cert,
            key: key
        }));
}

export function publish(topic, message) {
	return getOptions()
		.then(options => {
			let client = mqtt.connect(options);
			let deferred = Promise.defer();

			client.publish(topic, message, err => {
				client.end()
				
				if (!err) {
					deferred.resolve();
				} else {
					deferred.reject(err);
				}
			});

			return deferred.promise;
		});
}