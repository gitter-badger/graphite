graphite_render Cookbook
==========================

This cookbook is used for building rendering instances for [graphite](https://github.com/graphite-project/graphite-web)

rendering instances have very little requirements on them and they need no direct access to the data.

Requirements
------------

1. `runit` - `> 1.0.4`
  Provides runit support and the runit_service provider
2. `carbon` - `> 0.1.0` - [carbon](https://github.com/damm/carbon)
  Provides the carbon providers for installing and configuring the [carbon](https://github.com/graphite-project/carbon) backend
3. `graphite` - `> 0.1.1` - [graphite](https://github.com/damm/graphite)
  Provides the graphite proviers for installing and configuring the [graphite-web](https://github.com/graphite-project/graphite-web) composer.
4. [Python](http://github.com/opscode-cookbooks/python/)
  Provides virtualenv support and the pip provider
5. `git`
6. `build-essential`

Attributes
----------
No attributes are used

Usage
-----
#### graphite_render::default

Just include `graphite_render` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[graphite_render]"
  ]
}
```

Contributing
------------

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Author
==================
Author:: Scott M. Likens <scott@spam.likens.us>

Copyright 2013, Scott M. Likens

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
