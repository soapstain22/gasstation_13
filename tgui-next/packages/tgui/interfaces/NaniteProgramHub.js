import { Fragment } from 'inferno';
import { act } from '../byond';
import { Button, LabeledList, Section, NoticeBox, Tabs } from '../components';
import { map } from 'common/collections';

export const NaniteProgramHub = props => {
  const { state } = props;
  const { config, data } = state;
  const { ref } = config;
  const {
    detail_view,
    disk,
    has_disk,
    has_program,
    programs = {},
  } = data;
  return (
    <Fragment>
      <Section
        title="Program Disk"
        buttons={(
          <Fragment>
            <Button
              icon="eject"
              content="Eject"
              onClick={() => act(ref, "eject")}
            />
            <Button
              icon="minus-circle"
              content="Delete Program"
              onClick={() => act(ref, "clear")}
            />
          </Fragment>
        )}
      >
        {has_disk ? (
          has_program ? (
            <LabeledList>
              <LabeledList.Item label="Program Name">
                {disk.name}
              </LabeledList.Item>
              <LabeledList.Item label="Description">
                {disk.desc}
              </LabeledList.Item>
            </LabeledList>
          ) : (
            <NoticeBox>
              No Program Installed
            </NoticeBox>
          )
        ) : (
          <NoticeBox>
            Insert Disk
          </NoticeBox>
        )}
      </Section>
      <Section
        title="Programs"
        buttons={(
          <Fragment>
            <Button
              icon={detail_view ? "info" : "list"}
              content={detail_view ? "Detailed" : "Compact"}
              onClick={() => act(ref, "toggle_details")}
            />
            <Button
              icon="sync"
              content="Sync Research"
              onClick={() => act(ref, "refresh")}
            />
          </Fragment>
        )}
      >
        {programs !== null ? (
          <Tabs vertical>
            {map((cat_contents, category) => {
              const progs = cat_contents || [];
              // backend was sending stupid data that would have been annoying to fix
              const tabLabel = category.substring(0, (category.length - 8));
              return (
                <Tabs.Tab
                  key={category}
                  label={tabLabel}
                >
                  {detail_view ? (
                    progs.map(program => (
                      <Section
                        key={program.id}
                        title={program.name}
                        level={2}
                        buttons={(
                          <Button
                            icon="download"
                            content="Download"
                            disabled={!has_disk}
                            onClick={() => act(ref, "download", {program_id: program.id})}
                          />
                        )}
                      >
                        {program.desc}
                      </Section>
                    ))
                  ) : (
                    <LabeledList>
                      {progs.map(program => (
                        <LabeledList.Item
                          key={program.id}
                          label={program.name}
                          buttons={(
                            <Button
                              icon="download"
                              content="Download"
                              disabled={!has_disk}
                              onClick={() => act(ref, "download", {program_id: program.id})}
                            />
                          )}
                        />
                      ))}
                    </LabeledList>
                  )}
                </Tabs.Tab>
              );
            })(programs)}
          </Tabs>
        ) : (
          <NoticeBox>
            No nanite programs are currently researched.
          </NoticeBox>
        )}
      </Section>
    </Fragment>
  );
};
