BEGIN;

    update assets set value = replace(value, 'Tap for more info {$app_link}.', 'Log in to https://manager.meetflo.com/ for more info.'), updated = now()
    where "name" like '%.enterprise' and "type" = 'sms' and locale = 'en-us' and value like '%Tap for more info {$app_link}.%';
    
    update assets set value = replace(value, 'Tap here for more information. {$app_link}', 'Log in to https://manager.meetflo.com/ for more info.'), updated = now()
    where "name" like '%.enterprise' and "type" = 'sms' and locale = 'en-us' and value like  '%Tap here for more information. {$app_link}%';

    update assets set value = replace(value, 'Tap to learn more {$app_link}.', 'Log in to https://manager.meetflo.com/ for more info.'), updated = now()
    where "name" like '%.enterprise' and "type" = 'sms' and locale = 'en-us' and value like   '%Tap to learn more {$app_link}.%';

    update assets set value = replace(value, 'Tap for more information. {$app_link}', 'Log in to https://manager.meetflo.com/ for more info.'), updated = now()
    where "name" like '%.enterprise' and "type" = 'sms' and locale = 'en-us' and value like '%Tap for more information. {$app_link}%';

    update assets set value = replace(value, '. {$app_link}.', '. Log in to https://manager.meetflo.com/ for more info.'), updated = now()
    where "name" like '%.enterprise' and "type" = 'sms' and locale = 'en-us' and value like '%. {$app_link}.%';

    update assets set value = replace(value, ' {$app_link}.', '. Log in to https://manager.meetflo.com/ for more info.'), updated = now()
    where "name" like '%.enterprise' and "type" = 'sms' and locale = 'en-us' and value like '% {$app_link}.%';


    update assets set value = replace(value, 'Appuyez pour plus d''informations {$app_link}.', 'Connectez-vous à https://manager.meetflo.com/ pour plus d''informations.'), updated = now()
    where "name" like '%.enterprise' and "type" = 'sms' and locale = 'fr' and value like '%Appuyez pour plus d''informations {$app_link}%';
    
    update assets set value = replace(value, 'Cliquez ici pour plus d''informations. {$app_link}', 'Connectez-vous à https://manager.meetflo.com/ pour plus d''informations.'), updated = now()
    where "name" like '%.enterprise' and "type" = 'sms' and locale = 'fr' and value like  '%Cliquez ici pour plus d''informations. {$app_link}%';

    update assets set value = replace(value, 'Cliquez pour plus d''informations. {$app_link}', 'Connectez-vous à https://manager.meetflo.com/ pour plus d''informations.'), updated = now()
    where "name" like '%.enterprise' and "type" = 'sms' and locale = 'fr' and value like   '%Cliquez pour plus d''informations. {$app_link}%';

    update assets set value = replace(value, 'Appuyez pour en savoir plus {$app_link}.', 'Connectez-vous à https://manager.meetflo.com/ pour plus d''informations.'), updated = now()
    where "name" like '%.enterprise' and "type" = 'sms' and locale = 'fr' and value like '%Appuyez pour en savoir plus {$app_link}.%';

    update assets set value = replace(value, '. {$app_link}.', '. Connectez-vous à https://manager.meetflo.com/ pour plus d''informations.'), updated = now()
    where "name" like '%.enterprise' and "type" = 'sms' and locale = 'fr' and value like '%. {$app_link}.%';

    update assets set value = replace(value, ' {$app_link}.', '. Connectez-vous à https://manager.meetflo.com/ pour plus d''informations.'), updated = now()
    where "name" like '%.enterprise' and "type" = 'sms' and locale = 'fr' and value like '% {$app_link}.%';

COMMIT;
END;
