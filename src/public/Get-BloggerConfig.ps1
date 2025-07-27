<#
.SYNOPSIS
Obtains the current Blogger configuration for the session

#>
Function Get-BloggerConfig
{
  @{
    Template = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($BloggerSession.PandocTemplate)
    PandocMarkdownFormat = $BloggerSession.PandocMarkdownFormat
    PandocHtmlFormat = $BloggerSession.PandocHtmlFormat
    PandocAdditionalArgs = $BloggerSession.PandocAdditionalArgs
    BlogId = $BloggerSession.BlogId
    ExcludeLabels = $BloggerSession.ExcludeLabels
    AttachmentsDirectory = $BloggerSession.AttachmentsDirectory
  }
}