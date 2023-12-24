import 'package:flutter_test/flutter_test.dart';
import 'package:fsm/fsm.dart';

void main() {
  test('GetValue', () {
    Map<String, dynamic> value;
    // Data value.
    expect(getValue({'1': 'value_1'}, '1'), 'value_1');
    // Nested value.
    expect(
        getValue({
          '1': {
            '2': {'3': 'value_3'}
          }
        }, '1/2/3'),
        'value_3');
    // Additional keys.
    expect(
        getValue({
          '1': {
            '2_1': 2.1,
            '2': {'3_1': 3.1, '3': 'value_3'}
          },
          '1_1': 1.1
        }, '1/2/3'),
        'value_3');
    // Non-existent value returns null.
    value = {
      '1': {
        '2': {'3': 'value_3'}
      }
    };
    expect(getValue(value, '1/nonexistant_value/3'), null);
    // Non-existent path with type returns null.
    value = {'1': 'value_1'};
    expect(getValue(value, '1/2/3'), null);
    // Path hijacking with value that does not exist but exists later.
    value = {
      '1': {'3': 'value_3'}
    };
    expect(getValue(value, '1/2/3'), null);
    // Empty path should return root value.
    value = {
      '1': {
        '2': {'3': 'value_3'}
      }
    };
    expect(getValue(value, ''), value);
    // Empty path values and keys.
    value = {
      '': {
        '': {'': 'value_3'}
      }
    };
    expect(getValue(value, '///'), 'value_3');
  });

  test('UpdateData', () {
    // Merge single level map.
    expect(updateData({'1': 'value_1'}, {'2': 'value_2'}),
        {'1': 'value_1', '2': 'value_2'});
    // Merge nested map.
    expect(
        updateData({
          '1': {'1_1': 'value_1'}
        }, {
          '1': {'1_2': 'value_2'}
        }),
        {
          '1': {'1_1': 'value_1', '1_2': 'value_2'},
        });
    // Update value.
    expect(updateData({'1': 'value_1'}, {'1': 'value_2'}), {'1': 'value_2'});
    // Update nested value.
    expect(
        updateData({
          '1': {'1_1': 'value_1'}
        }, {
          '1': {'1_1': 'value_2'}
        }),
        {
          '1': {'1_1': 'value_2'}
        });
    // Update and merge.
    expect(
        updateData({
          '1': {'1_1': 'value_1', '1_2': 'value_2'},
          '2': 'value_2',
        }, {
          '1': {'1_2': 'value_3'},
          '3': 'value_3',
        }),
        {
          '1': {'1_1': 'value_1', '1_2': 'value_3'},
          '2': 'value_2',
          '3': 'value_3',
        });
    // Update gap.
    expect(
        updateData({
          '1': 'value_1'
        }, {
          '1': {
            '2': {'3': 'value_3'}
          }
        }),
        {
          '1': {
            '2': {'3': 'value_3'}
          }
        });
    // Update null.
    expect(
        updateData(null, {
          '1': {'1_1': 'value_1'}
        }),
        {
          '1': {'1_1': 'value_1'}
        });
  });

  test('BuildValueMap', () {
    // Top level map.
    expect(buildValueMap('value_1', ['field_1']), {'field_1': 'value_1'});
    // Nested map.
    expect(buildValueMap('value_1', ['field_1', 'field_2', 'field_3']), {
      'field_1': {
        'field_2': {'field_3': 'value_1'}
      }
    });
    // Build and update map with different type keys.
    expect(
        updateData({'field_1': 'value_1'},
            buildValueMap('value_1', ['field_1', 'field_2', 'field_3'])),
        {
          'field_1': {
            'field_2': {'field_3': 'value_1'}
          }
        });
  });

  test('SetData', () {
    // Set direct value.
    expect(setData('value_1', 'value_2', []), 'value_2');
    // Direct value overwrite.
    expect(setData({'field_1': 'value_1'}, 'value_2', []), 'value_2');
    // Set nested value.
    expect(setData('value_1', 'value_2', ['field_1', 'field_2']), {
      'field_1': {'field_2': 'value_2'}
    });
    // Nested value overwrite.
    expect(
        setData(
            {
              'field_1': {'field_2': 'value_1'}
            },
            'value_2',
            ['field_1', 'field_2']),
        {
          'field_1': {'field_2': 'value_2'}
        });
    // Deeper nested value.
    expect(
        setData({'field_1': 'value_1'}, 'value_1',
            ['field_1', 'field_2', 'field_3', 'field_4']),
        {
          'field_1': {
            'field_2': {
              'field_3': {'field_4': 'value_1'}
            }
          }
        });
    // Nested value append.
    expect(
        setData({'field_1': 'value_1', 'field_1_1': 'value_1_1'}, 'value_2',
            ['field_1', 'field_2', 'field_3']),
        {
          'field_1': {
            'field_2': {'field_3': 'value_2'}
          },
          'field_1_1': 'value_1_1'
        });
    // Overwrite null.
    expect(setData(null, 'value_1', ['field_1', 'field_2']), {
      'field_1': {'field_2': 'value_1'}
    });
    // Set null.
    expect(
        setData(
            {
              'field_1': {'field_2': 'value_1'}
            },
            null,
            ['field_1', 'field_2']),
        {
          'field_1': {'field_2': null}
        });
    // Set nested dynamic value.
    expect(
        setData(
            {
              'field_1': {
                'field_2': {'field_3': {}}
              }
            },
            320,
            ['field_1', 'field_2']),
        {
          'field_1': {'field_2': 320}
        });
    // Set duplicated nested keys.
    expect(
        setData({
          'field_1': {'field_2': 'value_1'}
        }, {
          'field_1': {
            'field_2': {
              'field_3': {'field_4': 'value_1'}
            }
          }
        }, [
          'field_1',
          'field_2',
          'field_3'
        ]),
        {
          'field_1': {
            'field_2': {
              'field_3': {
                'field_1': {
                  'field_2': {
                    'field_3': {'field_4': 'value_1'}
                  }
                }
              }
            }
          }
        });
    // Set duplicated nested keys #2.
    expect(
        setData({
          'field_1': 'value_1'
        }, {
          'field_1': {
            'field_2': {
              'field_3': {'field_4': 'value_1'}
            }
          }
        }, [
          'field_1',
          'field_2',
          'field_3'
        ]),
        {
          'field_1': {
            'field_2': {
              'field_3': {
                'field_1': {
                  'field_2': {
                    'field_3': {'field_4': 'value_1'}
                  }
                }
              }
            }
          }
        });
    // Duplicate paths.
    expect(
        setData({
          'field_1': 'value_1'
        }, {
          'field_1': {
            'field_1': {
              'field_1': {'field_1': 'value_1'}
            }
          }
        }, [
          'field_1',
          'field_1',
          'field_1'
        ]),
        {
          'field_1': {
            'field_1': {
              'field_1': {
                'field_1': {
                  'field_1': {
                    'field_1': {'field_1': 'value_1'}
                  }
                }
              }
            }
          }
        });
    // Duplicate paths #2.
    expect(
        setData({
          'field_1': {
            'field_1': {
              'field_1': {'field_1': 'value_1'}
            }
          }
        }, {
          'field_1': {
            'field_1': {
              'field_1': {'field_1': 'value_1'}
            }
          }
        }, [
          'field_1',
          'field_1',
          'field_1'
        ]),
        {
          'field_1': {
            'field_1': {
              'field_1': {
                'field_1': {
                  'field_1': {
                    'field_1': {'field_1': 'value_1'}
                  }
                }
              }
            }
          }
        });
    // Duplicate paths #3.
    expect(
        setData({
          'field_1': {
            'field_1': {
              'field_1': {'field_1': 'value_1'}
            }
          }
        }, {
          'field_1': {
            'field_1': {
              'field_1': {'field_1': 'value_1'}
            }
          }
        }, [
          'field_1',
        ]),
        {
          'field_1': {
            'field_1': {
              'field_1': {
                'field_1': {'field_1': 'value_1'}
              }
            }
          }
        });
  });
}
