import { NavigationContainer } from '@react-navigation/native'
import * as Linking from 'expo-linking'
import { useMemo } from 'react'

export function NavigationProvider({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <NavigationContainer
      linking={useMemo(
        () => ({
          prefixes: [Linking.createURL('/')],
          config: {
            initialRouteName: 'home',
            screens: {
              home: '',
              media: 'media',
              posts: 'posts',
              events: 'events',
              userDetails: 'user/:id',
              usernameDetails: ':username',
              postDetails: 'post/:postId',
              eventDetails: 'event/:eventId',
              groupDetails: 'g/:shortname',
              groupPostDetails: 'g/:shortname/p/:postId',
              groupEventDetails: 'g/:shortname/e/:eventId',
              groupEventInstanceDetails: 'g/:shortname/e/:eventId/:instanceId',
              people: 'people',
              followRequests: 'people/follow_requests',
              about: 'about',
              about_jonline: 'about_jonline',
            },
          },
        }),
        []
      )}
    >
      {children}
    </NavigationContainer>
  )
}
