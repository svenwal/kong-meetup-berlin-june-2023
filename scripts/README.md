# Lightweight CI/CD examples

The scripts in this folder can be used to show how potential CI/CD chains could look like when using the full toolset of Kong (from Insomnia/inso -> decK -> Gateway -> Developer Portal)

# Demo Scene: UUID with inso cli (see below same with kced)

## Prerequisites

* Kong Enterprise and PROXY_URL and ADMIN_URL set or Konnect (SaaS) account with the connection settings exported as environment variables KONNECT_API_TOKEN, KONNECT_REGION and KONNECT_RUNTIME_GROUP_NAME (plus also PROXY_URL)
* decK `https://docs.konghq.com/deck/latest/`
* Insomia installed and workspace imported (see below) `https://insomnia.rest/products/insomnia`
* inso cli installed `https://insomnia.rest/products/inso`
* httpie `https://httpie.io/`
* yq `https://github.com/mikefarah/yq`
* jq `https://jqlang.github.io/jq/`

IMPORTANT: `kong_pipeline_inso_deck_kong.sh` requires importing the https://github.com/svenwal/uuid-generator-workspace (public repo) into Insomnia. This enables the view of the OpenAPI and the automated tests using inso cli to work you need to import the workspace: `https://docs.insomnia.rest/insomnia/git-sync`

## Features and order

The script waits for any step for ENTER to be pressed before it starts executing the command to give you time to explain what is about to happen

1. The first step is about opening Insomnia and showing the OpenAPI spec of the UUID service, make an example debug call and test the API (two tests on general availibity (returns 200) and JSON paramters available included).  You also should show and explain the concepts of the button to export the declarative configuration
2. The scripts checks out the YAML file from the development branch and uses inso cli to check the syntax (lint)
3. Explain now that the backend service would have been created and published now - we are using a public website instead. The script now executes the same test (200 OK and UUID available) as we have seen in Insomnia in an automated way
4. We are assuming that everything is fine so next step is that our backend is pulled to main - which we are simulating by checking out the main trunk now
5. The big moment: we assume that the backend service has now been deployed into production so we are using inso cli to generate a Kong YAML file, validate the YAML file using decK and then sync the service and route  to Kong
6. We patch the OpenAPI spec to not point to the actual backend but instead to the Kong proxy and publish this version to the developer portal
7. All temp files get removed

# Demo Scene: UUID with kced

## Prerequisites

* Kong Enterprise and PROXY_URL and ADMIN_URL set or Konnect (SaaS) account with the connection settings exported as environment variables KONNECT_API_TOKEN, KONNECT_REGION and KONNECT_RUNTIME_GROUP_NAME (plus also PROXY_URL)
* decK `https://docs.konghq.com/deck/latest/` (only during beta phase of kced)
* Insomia installed and workspace imported (see below) `https://insomnia.rest/products/insomnia`
* kced installed `https://github.com/Kong/go-apiops`
* httpie `https://httpie.io/`
* yq `https://github.com/mikefarah/yq`
* jq `https://jqlang.github.io/jq/`

IMPORTANT: `kong_pipeline_kced_kong.sh` requires importing the https://github.com/svenwal/uuid-generator-workspace (public repo) into Insomnia. This enables the view of the OpenAPI and the automated tests using inso cli to work you need to import the workspace: `https://docs.insomnia.rest/insomnia/git-sync`

## Features and order

The script waits for any step for ENTER to be pressed before it starts executing the command to give you time to explain what is about to happen

1. The first step is about opening Insomnia and showing the OpenAPI spec of the UUID service, make an example debug call and test the API (two tests on general availibity (returns 200) and JSON paramters available included).  You also should show and explain the concepts of the button to export the declarative configuration
2. The scripts checks out the YAML file from the development branch and uses inso cli to check the syntax (lint)
3. Explain now that the backend service would have been created and published now - we are using a public website instead. The script now executes the same test (200 OK and UUID available) as we have seen in Insomnia in an automated way
4. We are assuming that everything is fine so next step is that our backend is pulled to main - which we are simulating by checking out the main trunk now
5. The big moment: we assume that the backend service has now been deployed into production so we are using kced to generate a Kong YAML file, validate the YAML file using decK and then sync the service and route to Kong
6. We patch the OpenAPI spec to not point to the actual backend but instead to the Kong proxy and publish this version to the developer portal
7. All temp files get removed

