global interface ISlackCommand {
    //returns the response to the slack user
    SlackCommand.SlackResponse getResponse(SlackCommand.SlackCommandParams params);

    //can be used to execute DML after we send our response.  Must be seperated due to DML after callout limits
    void runDML();
}