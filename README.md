# SFDC Slack Slash-Commands

A framework for easily adding Slack Slash Commands to Salesforce.

![SFDC Slack Slash Commands](https://raw.githubusercontent.com/ChuckJonas/SfdcSlackSlashCommands/master//slackslashcommands.gif)

## Setup

1. Install on SFDC `src`

2. `Develop` - `Sites` - `New`.  Note site URL for next step.

3. `Public Access Settings` - `Apex Class Access`: Allow `SlackCommandHandler`.

4. Register Slack Slash Commands.  Set `URL` == `[SFDC Site Url]/webhooks/services/apexrest/slack`

5. Set Label `Slack_API_Token` == `Token` From Step #4

6. Test by running `/[cmd] help`. You can adjust the help response by changing the `Slack_Command_Help_Message` custom label


## Map Slack Users to SFDC (Optional)

1. Add a custom field called `Slack_User_Id__c` to the Salesforce `User` Object

2. Use [users.list](https://api.slack.com/methods/users.list/test) to retrieve slack users Ids

3. Set `User.Slack_User_Id__c`

## Adding your first command

### Add Command Class

Create a new class that inherits from `ISlackCommand` and has a 0 param constructor.  Implement `getReponse(SlackCommand.SlackCommandParams params)` function.

``` java
//Two commands around account object
// 1: /[cmd] account new [name]: creates a new account with [name]
// 2: /[cmd] account list: list recently viewed accounts of user
public class AccountCommand implements ISlackCommand{
    public SlackCommand.SlackResponse getResponse(SlackCommand.SlackCommandParams params){
        try{
            User u = [SELECT Id FROM User WHERE Slack_User_Id__c =:params.userId];
            String instance = [SELECT InstanceName FROM Organization LIMIT 1].InstanceName;
            if(params.text.startsWith('accounts new')){
                Account acc = new Account(Name = params.text.split(' ')[2], OwnerId = u.Id);
                insert acc;

                String msg = String.format(
                    'Account Created: <https://{0}.salesforce.com/{1}|{2}>',
                    new String[]{
                        instance,
                        acc.Id,
                        acc.Name
                    }
                );
                return new SlackCommand.SlackResponse(msg);
            }else if(params.text.startsWith('accounts list')){
                List<String> accs = new List<String>();
                for(Account acc : [SELECT Name
                                    FROM Account WHERE OwnerId = :u.Id
                                    ORDER BY LastViewedDate DESC Limit 10]){
                    accs.add(String.format(
                        '<https://{0}.salesforce.com/{1}|{2}>',
                        new String[]{
                            instance,
                            acc.Id,
                            acc.Name
                        }
                    ));
                }
                return new SlackCommand.SlackResponse(String.join(accs,'\n'));
            }else{
                return new SlackCommand.SlackResponse('No Matching Command found... Try `/[cmd] account new [name]` or `/[cmd] account list`');
            }
        }catch(Exception e){
            return new SlackCommand.SlackResponse('Error:' + e.getMessage());
        }
    }
}
```

### Register Command

`Develop` - `Custom Metadata Types` - `Slack Command` - `Manage Records` - `New`.

* Set `Class` = `AccountCommand`

* Set `Command Key` = `accounts`.  This is the first keyword after your `/[cmd]`.  In our example, all commands that start with `\[cmd] accounts` will get routed to this class.

* Check `Active`

* Leave `Immedate` unchecked.  Immediate commands must respond within 3000ms.  Only check this if you are confident your command will do so

## References

* [Slack Slash Commands](https://api.slack.com/slash-commands)


## License
MIT