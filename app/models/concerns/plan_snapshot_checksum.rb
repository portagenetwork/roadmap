# frozen_string_literal: true

require 'digest/md5'

# This concern provides deterministic checksum generation for PlanSnapshot records.
# The same logical content will always produce the same checksum, regardless of:
#   - Hash key ordering
#   - Nested hash ordering
#   - Whether the input is provided as a Hash or JSON string
module PlanSnapshotChecksum
  # Checksum calculation process:
  #
  #   1. Parse `rda_json` and `extension_json` into Ruby objects if they are JSON strings.
  #      - Ensures both inputs are normalized to the same Ruby data structures.
  #
  #   2. Normalize hashes by recursively sorting all hash keys via `deep_sort`.
  #      - Produces a deterministic structure for logically equivalent content.
  #      - Array ordering is preserved.
  #
  #   3. Serialize the normalized objects into JSON strings.
  #      - Creates a consistent string representation of the data.
  #
  #   4. Compute the MD5 hex digest from the serialized content.
  #      - Produces a stable checksum/fingerprint for comparison and change detection.

  def self.calculate(rda_json, extension_json)
    rda_str = normalize_json_for_checksum(rda_json)
    ext_str = normalize_json_for_checksum(extension_json)
    Digest::MD5.hexdigest(rda_str + ext_str)
  end

  # Normalize a hash or JSON string for checksumming: parse, deep_sort, and serialize
  def self.normalize_json_for_checksum(obj)
    hash = obj.is_a?(String) ? JSON.parse(obj) : obj
    sorted = deep_sort(hash)
    JSON.generate(sorted)
  end

  # Recursively normalizes a Ruby object into a deterministic structure.
  # - Hashes are key-sorted at every level
  # - Arrays preserve their ordering
  def self.deep_sort(obj)
    case obj
    when Hash
      # Sort keys and rebuild hash in a deterministic order
      obj.keys.sort.each_with_object({}) do |k, h|
        h[k] = deep_sort(obj[k])
      end
    when Array
      # normalize each element (preserve array order)
      obj.map { |v| deep_sort(v) }
    else
      obj
    end
  end

  private_class_method :normalize_json_for_checksum, :deep_sort
end
