import _ from 'lodash';
import { UserDetails, RecordImage } from "../interfaces";
import dbHelper from '../database/DbHelper';
import { updateTagsInActiveCampaign } from '../active-campaign/activeCampaignTagger';

export const handleUserDetails = async (userDetails: RecordImage<UserDetails>): Promise<void> => {
  const newUserDetails = userDetails.new;
  const oldUserDetails = userDetails.old;

  try {
    console.log(`Retrieving user email for user id ${newUserDetails.user_id}.`);
    const userEmail = await dbHelper.retrieveUserEmail(newUserDetails.user_id);
    console.log(`Retrieved user email for user id ${newUserDetails.user_id}: ${userEmail}`);

    const userInfo = {
      email: userEmail,
      firstName: newUserDetails.firstname,
      lastName: newUserDetails.lastname
    };
    const oldLanguageTag = !_.isEmpty(oldUserDetails.locale) ? oldUserDetails.locale.slice(0, 2) : 'en';
    const newLanguageTag = !_.isEmpty(newUserDetails.locale) ? newUserDetails.locale.slice(0, 2) : 'en';

    return updateTagsInActiveCampaign(userInfo, newLanguageTag, oldLanguageTag);

  } catch (err) {
    console.error(`Error while handling user details for user id ${newUserDetails.user_id}: ${err}`);
    return Promise.resolve();
  }
};