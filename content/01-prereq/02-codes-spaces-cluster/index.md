## Codespaces Cluster Set Up

Create a new instance or use an existing instance of the `aiops-easytrade` Codespaces.

[aiops-easytrade](https://github.com/dt-wv/aiops-easytrade/tree/main)

Navigate to the Github repository.  Click on `Code`.  Click on `Codespaces`.  Click on `New with options`.

![github cluster repo](../../../assets/images/prereq-github_cluster_repo.png)

Choose the Branch `code-spaces`.  Choose the Dev Container Configuration `Kubernetes in Codespaces`.

Choose a Region near your Dynatrace tenant.

Choose Machine Type `4-core`.

![github new codespaces](../../../assets/images/prereq-github_cluster_new_codespaces.png)

Allow the Codespace instance to fully initialize.  It is not ready yet.

![github codespace launch](../../../assets/images/prereq-github_codespace_launch.png)

The Codespace instance will run the post initialization scripts.

![github codespace ](../../../assets/images/prereq-github_codespace_create.png)

The Codespaces require the input of the previously created API Tokens and OAuth Client.  

![github codespace tokens](../../../assets/images/prereq-github_codespace_tokens.png)  

Enable port-forwarding to the reverseproxy webfrontend

![port-forwarding](../../../assets/images/click_ports.png)

Hover over the ***private*** visibility of the port and right click.

![right click](../../../assets/images/right_click.png)  

Put it on ***Public***  

![public](../../../assets/images/public_port.png)  


Cick on the globe in the Forwarded Address link.  

![Open in Browser](../../../assets/images/open_in_browser.png)  

This will open a new browser tab with a report on a unsafe page.

![unsafe page](../../../assets/images/unsafe_page_continue.png)

When the Codespace instance is idle, validate the `easytrade` pods are running.

Command:
```sh
kubectl get pods -n easytrade
```

![github codespace ready](../../../assets/images/prereq-github_codespace_ready.png)

Put the codespaces idle timer to ***240*** minutes.  

![codespaces settings](../../../assets/images/codespaces_settings.png)

![codespaces](../../../assets/images/codespaces_codespaces.png)

![codespaces default idle timer](../../../assets/images/codespaces_default_idle_timer.png)