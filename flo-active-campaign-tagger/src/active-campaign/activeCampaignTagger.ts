import axios from 'axios';
import querystring from 'querystring';
import config from '../config';
import { UserInfo } from '../interfaces';

const postActionToActiveCampaign = async (action: string, data: string): Promise<any> => {
  const response = await axios({
    method: 'post',
    url: `${config.activeCampaignBaseUrl}/admin/api.php`,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    params: {
      api_action: action,
      api_key: config.activeCampaignApiKey,
      api_output: 'json'
    },
    data: data
  });
  return response.data;
}

const createContactWithTag = async (user: UserInfo, tag: string): Promise<any> => {
  const data = querystring.stringify({
    tags: tag,
    email: user.email,
    first_name: user.firstName,
    last_name: user.lastName
  });
  return postActionToActiveCampaign('contact_add', data);
}

const addTagToExistingContact = async (user: UserInfo, tag: string): Promise<any> => {
  const data = querystring.stringify({
    tags: tag,
    email: user.email
  });
  return postActionToActiveCampaign('contact_tag_add', data);
}

const removeTagFromExistingContact = async (user: UserInfo, tag: string): Promise<any> => {
  const data = querystring.stringify({
    tags: tag,
    email: user.email
  });
  return postActionToActiveCampaign('contact_tag_remove', data);
}

export const updateTagsInActiveCampaign = async (user: UserInfo, tagToAdd: string, tagToRemove?: string): Promise<void> => {
  try {
    console.log(`Creating contact with email ${user.email} and '${tagToAdd}' tag.`);
    const createContactResponse = await createContactWithTag(user, tagToAdd);

    if (createContactResponse.result_code === 1) {
      console.log(`Successfully created contact with email ${user.email} and '${tagToAdd}' tag.`);
    } else {
      console.log(`Contact with email ${user.email} already exists. Adding '${tagToAdd}' tag to contact.`);

      if (tagToRemove) {
        const removeTagResponse = await removeTagFromExistingContact(user, tagToRemove);
        if (removeTagResponse.result_code === 1) {
          console.log(`Successfully removed '${tagToRemove}' tag from contact ${user.email}.`);
        } else {
          console.warn(`Could not remove '${tagToRemove}' tag from contact ${user.email}: ${removeTagResponse.result_message}.`);
        }
      }

      const addTagResponse = await addTagToExistingContact(user, tagToAdd);
      if (addTagResponse.result_code === 1) {
        console.log(`Successfully added '${tagToAdd}' tag to contact ${user.email}.`);
      } else {
        console.warn(`Could not add '${tagToAdd}' tag to contact ${user.email}: ${addTagResponse.result_message}.`);
      }
    }
  } catch (err) {
    console.error(`Error while updating tags for contact ${user.email}. TagToAdd: ${tagToAdd}. TagToRemove: ${tagToRemove}.`);
  }
}
