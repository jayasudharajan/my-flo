import _ from 'lodash';
import { ScheduledEvent } from 'aws-lambda';
import { S3Client } from '../storage/aws-s3-client';
import axios from 'axios';
import config from '../config';

const s3Client = new S3Client();

async function getSendWithUsData(path: string) {
  try {
    return await axios.request({
      method: 'GET',
      url: path,
      timeout: 60000,
      auth: {
        username: config.sendWithUsApiKey,
        password: ''
      }
    });
  } catch (error) {
    console.error('Error retrieving from path: ' + `${path}`, '\nError: ', error.message);
  };
  return null;
};
 
async function uploadToS3(fileName: string, data: any) {
  try {
    const s3Response = await s3Client.put(config.s3Bucket, `${fileName}.json`, JSON.stringify(data));
    console.log('Template: ', `${fileName}`, ' successfully saved.');
    console.log(s3Response);
  }
  catch (error) {
    console.error('Error uploading to S3: ', error.message);
  }
};

export const handleEvent = async (_event: ScheduledEvent): Promise<void> => {

  console.log('SendWithUs templates download starts... \n');
  const templates = await getSendWithUsData(config.sendWithUsBaseUrl);

  if (!_.isNil(templates)) {
    console.log('\nUpload general list of templates. \n');
    await uploadToS3('generalList', templates.data);

    const templateIds = templates.data.map((t: { id: String; }) => t.id);

    console.log('\nUploading every template... \n');
    templateIds.forEach(
      async (templateId: string) => {
        const pathToTemplate = config.sendWithUsBaseUrl + `/${templateId}/versions`;
        const versions = await getSendWithUsData(pathToTemplate);
        if (!_.isNil(versions)) {
          await uploadToS3(templateId, versions.data);
        } else {
          console.error('Error trying to retrieve template: ' + `${templateId}`);
        }
      }
    );
  };
}