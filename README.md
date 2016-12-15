# SFDC Slack Slash-Commands

A framework for adding Slack Slash Commands to Salesforce.  Allows you to easily write your own slack slash commands that run on salesforce.

## Setup

1. Install on SFDC `src`

2. `Develop` - `Sites` - `New`.  Note site URL for next step.

3. `Public Access Settings` - `Apex Class Access`: Allow `SlackCommandHandler`.

4. Register Slack Slash Commands.  Set `URL` == `[SFDC Site Url]/webhooks/services/apexrest/slack`

5. Set Label `Slack_API_Token` == `Token` From Step #4

6. Test by running `/[cmd] help`. You can adjust the help response by changing the `Slack_Command_Help_Message` custom label

## Adding your first command

### Add Command Class

Create a new class that inherits from `ISlackCommand`.  Implement `getReponse(SlackCommand.SlackCommandParams params)` and `runDML()`.  Must have 0 param constructor.

``` java
public class Foo implements ISlackCommand{

    public SlackCommand.SlackResponse getResponse(SlackCommand.SlackCommandParams params){
        if(params.text == 'foo bar'){
            return new SlackCommand.SlackResponse('FOOOOOOOO BAAAAAAR!');
        }else if(params.text == 'foo hello'){
            return new SlackCommand.SlackResponse('Hello! ' + params.userName);
        }else{
            return new SlackCommand.SlackResponse('Not sure what you want... Try `/[cmd] foo bar` or `/[cmd] foo hello`');
        }
    }

    //===NOT IMPLEMENTED===
    public void runDML(){}

}
```

### Register Command

`Develop` - `Custom Metadata Types` - `Slack Command` - `Manage Records` - `New`.

* Set `Class` = `Foo`

* Set `Command Key` = `foo`

* Check `Active`

* Check `Immedate`.  Immediate commands must respond within 3000ms.  For commands that take longer, leave unchecked.


## User Specific Commands

1. Add a custom field called `Slack_User_Id__c` to the Salesforce `User` Object

2. Use [users.list](https://api.slack.com/methods/users.list/test) to retrieve users Ids

3. Map Slack Users -> SFDC users by setting `Slack_User_Id__c`

4. In your command, you can now figure out which users is making the request.  The example below shows a command that will return the last account the user edited.

``` java
    public SlackCommand.SlackResponse getResponse(SlackCommand.SlackCommandParams params){
        User u = [SELECT Id FROM User WHERE Slack_User_Id__c =:params.userId];
        Account acc = [SELECT Name FROM Account WHERE LastModifiedBy =:u.Id ORDER BY LastModifiedDate DESC LIMIT 1];
        return new SlackCommand.SlackResponse(acc.Name);
    }
```

## References

* [Slack Slash Commands](https://api.slack.com/slash-commands)