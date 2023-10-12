import t from 'tcomb-validation';

const TMQTTCertConfig = t.struct({
	bucket: t.String,
	clientCertificatePath: t.String,
	clientKeyPath: t.String,
	caFilePath: t.String,
	caV2FilePath: t.String
});

TMQTTCertConfig.create = data => TMQTTCertConfig(data);

export default TMQTTCertConfig;