workflow "Tweet on push to default branch" {
  on = "push"
  resolves = ["Tweet"]
}

action "Tweet" {
  uses = "./" # use itself :)
  secrets = ["GITHUB_TOKEN", "TWITTER_API_KEY", "TWITTER_API_SECRET_KEY", "TWITTER_ACCESS_TOKEN", "TWITTER_ACCESS_TOKEN_SECRET"]
}

# "push" event won’t work on forks, hence the 2nd workflow with "pull_request"
workflow "Preview and validate tweets on pull requests" {
  on = "pull_request"
  resolves = ["Preview"]
}

action "Preview" {
  uses = "./" # use itself :)
  secrets = ["GITHUB_TOKEN"]
}

workflow "Test on push" {
  on = "push"
  resolves = ["npm test (push)"]
}

action "npm ci (push)" {
  uses = "docker://node:alpine"
  runs = "npm"
  args = "ci"
}

action "npm test (push)" {
  needs = "npm ci (push)"
  uses = "docker://node:alpine"
  runs = "npm"
  args = "test"
}

workflow "Test on pull_request" {
  on = "pull_request"
  resolves = ["npm test (pull request)"]
}

action "checkout pull request" {
  uses = "gr2m/git-checkout-pull-request-action@master"
}

action "npm ci (pull request)" {
  needs = "checkout pull request"
  uses = "docker://node:alpine"
  runs = "npm"
  args = "ci"
}

action "npm test (pull request)" {
  needs = "npm ci (pull request)"
  uses = "docker://node:alpine"
  runs = "npm"
  args = "test"
}

workflow "Release" {
  on = "push"
  resolves = ["npx semantic-release"]
}

action "filter: master branch" {
  needs = "npm test (push)"
  uses = "actions/bin/filter@master"
  args = "branch master"
}

action "npx semantic-release" {
  needs = "filter: master branch"
  uses = "docker://timbru31/node-alpine-git"
  runs = "npx"
  args = "semantic-release"
  secrets = ["GH_TOKEN"] # temporary workaround until semantic-release works in action environment
}
