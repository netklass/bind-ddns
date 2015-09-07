#
# Copyright (c) 2015 Sam4Mobile
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Modify CommonSandbox to generate nodes from suites
# Generated nodes follow this pattern:
#   {
#     "id": "#{suite[:driver][:hostname]}",
#     "automatic": {
#       "fqdn": "#{suite[:driver][:hostname]}",
#       "roles": #{roles}
#     }
#   }
# They are overrided by the user ones (files) in case of conflict

require 'kitchen/provisioner/chef/common_sandbox'

module Kitchen
  module Provisioner
    module Chef

      class CommonSandbox
        alias_method :prepare_official, :prepare

        def prepare(component, opts = {})
          generate_nodes(component, opts) if component == :nodes
          # Override genenated files by user files
          prepare_official(component, opts)
        end

        def generate_nodes(component, opts)
          dest = File.join(sandbox_path, opts.fetch(:dest_name,component.to_s))
          FileUtils.mkdir_p(dest)

          nodes = $suites.map do |suite|
            node = generate_node(suite)
            unless node.nil?
              File.write("#{dest}/#{suite[:driver][:hostname]}.json", node)
            end
          end
        end

        def generate_node(suite)
          if suite[:provisioner].nil? || suite[:driver][:hostname].nil? ||
            suite[:driver].nil? || suite[:provisioner][:run_list].nil?
            return nil
          end

          roles = suite[:provisioner][:run_list].map do |item|
            role = item.match(/role\[([\w-]+)\]/)
            role[1] unless role.nil?
          end.reject(&:nil?)

          <<-eos.gsub(/^ {10}/, '')
          {
            "id": "#{suite[:driver][:hostname]}",
            "automatic": {
              "fqdn": "#{suite[:driver][:hostname]}",
              "roles": #{roles}
            }
          }
          eos
        end
      end

    end
  end
end
