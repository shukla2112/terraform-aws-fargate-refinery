DryRun = ${dry_run}
DryRunFieldName = "${dry_run_field_name}"

Sampler = "DeterministicSampler"
SampleRate = 1

%{ for sampler in samplers ~}
[${sampler.dataset_name}]
  %{ for option in sampler.options ~}
    ${option.name} = ${ try(
                          tonumber(option.value),
                          tobool(option.value),
                          length(regexall("\\[", option.value)) == 0 ? "\"${option.value}\"" : option.value,
                      )}
  %{ endfor ~}

  %{ if length(sampler.rules) == 0 }
  %{ else }
  %{ for rule in sampler.rules ~}
    [[${sampler.dataset_name}.rule]]
        SampleRate = ${ try(
                         tonumber(rule.sample_rate),
                         tobool(rule.sample_rate),
                         "\"${rule.sample_rate}\""
                        )}
        Name = ${ try(
                   tonumber(rule.name),
                   tobool(rule.name),
                   "\"${rule.name}\""
                  )}
        [[${sampler.dataset_name}.rule.condition]]
        field = ${ try(
                    tonumber(rule.condition["field"]),
                    tobool(rule.condition["field"]),
                    "\"${rule.condition["field"]}\""
                   )}
        operator = ${ try(
                    tonumber(rule.condition["operator"]),
                    tobool(rule.condition["operator"]),
                    "\"${rule.condition["operator"]}\""
                   )}
        value = ${ try(
                    tonumber(rule.condition["value"]),
                    tobool(rule.condition["value"]),
                    "\"${rule.condition["value"]}\""
                   )}
 
  %{ endfor ~}
  %{ endif }
%{ endfor ~}
