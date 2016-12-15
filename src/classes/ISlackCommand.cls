// Author: Charlie Jonas (Charlie@callwaycloudconsulting.com)
//Interface all Slack Commands must inherit from
global interface ISlackCommand {

    //returns the response to the slack user
    SlackCommand.SlackResponse getResponse(SlackCommand.SlackCommandParams params);
}